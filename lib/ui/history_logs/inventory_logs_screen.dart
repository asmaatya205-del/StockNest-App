import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/inventory_log_model.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/product_provider.dart';
import '../../domain/providers/warehouse_provider.dart' show LoadingStatus;

class InventoryLogsScreen extends StatefulWidget {
  const InventoryLogsScreen({super.key});

  @override
  State<InventoryLogsScreen> createState() => _InventoryLogsScreenState();
}

class _InventoryLogsScreenState extends State<InventoryLogsScreen> {
  LogType? _filter;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      context.read<ProductProvider>().loadUserLogs(userId);
    }
  }

  /// Filters logs locally based on both the selected LogType and a range of bounds constraints.
  List<InventoryLogModel> _filtered(List<InventoryLogModel> logs) {
    return logs.where((l) {
      // Operation Type Filter Evaluation
      if (_filter != null && l.logType != _filter) return false;

      // Temporal Boundary Range Evaluation
      if (_fromDate != null || _toDate != null) {
        final logDate = DateTime.tryParse(l.createdAt);
        if (logDate == null) return false;
        if (_fromDate != null && logDate.isBefore(_fromDate!)) return false;
        if (_toDate != null && logDate.isAfter(_toDate!.add(const Duration(days: 1)))) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _toDate = picked);
  }

  void _clearDates() => setState(() {
    _fromDate = null;
    _toDate = null;
  });

  /// Assembles an explicit tabular data statement structure layout mapped to a multipage A4 canvas document,
  /// exports statistics summaries, and triggers the standard operating system print share drawer router.
  Future<void> _exportPdf(List<InventoryLogModel> logs) async {
    setState(() => _isExporting = true);

    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('yyyy-MM-dd');
      final now = dateFormat.format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header Component Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Inventory Report',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Generated: $now',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Condition Constraints Summary Card Block
            if (_filter != null || _fromDate != null || _toDate != null)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'Filters: ${_filter != null ? _filter!.label : 'All Types'}'
                      '${_fromDate != null ? ' | From: ${dateFormat.format(_fromDate!)}' : ''}'
                      '${_toDate != null ? ' | To: ${dateFormat.format(_toDate!)}' : ''}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ),
            pw.SizedBox(height: 16),

            // Analytics Totals Snapshot Counters Layout
            pw.Row(
              children: [
                _pdfSummaryBox('Total Logs', '${logs.length}', PdfColors.blue),
                pw.SizedBox(width: 8),
                _pdfSummaryBox(
                  'Stock In',
                  '${logs.where((l) => l.logType == LogType.stockIn).length}',
                  PdfColors.green,
                ),
                pw.SizedBox(width: 8),
                _pdfSummaryBox(
                  'Stock Out',
                  '${logs.where((l) => l.logType == LogType.stockOut).length}',
                  PdfColors.red,
                ),
                pw.SizedBox(width: 8),
                _pdfSummaryBox(
                  'Transfers',
                  '${logs.where((l) => l.logType == LogType.transfer).length}',
                  PdfColors.purple,
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Tabular Grid Structure
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('Product', isHeader: true),
                    _pdfCell('Warehouse', isHeader: true),
                    _pdfCell('Type', isHeader: true),
                    _pdfCell('Qty', isHeader: true),
                    _pdfCell('Date', isHeader: true),
                  ],
                ),
                ...logs.map((log) => pw.TableRow(
                  children: [
                    _pdfCell(log.productName ?? '-'),
                    _pdfCell(log.fromWarehouseName ?? '-'),
                    _pdfCell(log.logType.label),
                    _pdfCell(
                      '${log.logType == LogType.stockOut ? '-' : '+'}${log.quantity}',
                    ),
                    _pdfCell(
                      log.createdAt.length > 10
                          ? log.createdAt.substring(0, 10)
                          : log.createdAt,
                    ),
                  ],
                )),
              ],
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'inventory_report_$now.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  pw.Widget _pdfSummaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                )),
            pw.Text(label,
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Color _logColor(LogType t) {
    switch (t) {
      case LogType.stockIn:    return AppColors.success;
      case LogType.stockOut:   return AppColors.danger;
      case LogType.transfer:   return AppColors.primary;
    }
  }

  String _formatDate(DateTime d) => DateFormat('MMM dd').format(d);

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inventory Logs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          Consumer<ProductProvider>(
            builder: (_, provider, __) {
              final logs = _filtered(provider.logs);
              return _isExporting
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded),
                tooltip: 'Export PDF',
                onPressed: logs.isEmpty ? null : () => _exportPdf(logs),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (_, provider, __) {
          if (provider.status == LoadingStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.status == LoadingStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  provider.errorMessage ?? 'Failed to load logs.',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final logs = _filtered(provider.logs);

          return Column(
            children: [
              // ── Filter Segment (Horizontal Layout Type Scroller) ──
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                    vertical: AppSpacing.sm,
                  ),
                  children: [
                    _LogFilterChip(
                      label: 'All',
                      selected: _filter == null,
                      color: AppColors.primary,
                      onTap: () => setState(() => _filter = null),
                    ),
                    ...LogType.values.map((t) => _LogFilterChip(
                      label: t.label,
                      selected: _filter == t,
                      color: _logColor(t),
                      onTap: () => setState(() => _filter = t),
                    )),
                  ],
                ),
              ),

              // ── Temporal Query Boundaries Row Component ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickFromDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: _fromDate != null
                                ? AppColors.primarySurface
                                : AppColors.surface,
                            borderRadius: AppRadius.inputRadius,
                            border: Border.all(
                              color: _fromDate != null
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 14,
                                  color: _fromDate != null
                                      ? AppColors.primary
                                      : AppColors.textHint),
                              const SizedBox(width: 6),
                              Text(
                                _fromDate != null
                                    ? _formatDate(_fromDate!)
                                    : 'From date',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _fromDate != null
                                      ? AppColors.primary
                                      : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickToDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: _toDate != null
                                ? AppColors.primarySurface
                                : AppColors.surface,
                            borderRadius: AppRadius.inputRadius,
                            border: Border.all(
                              color: _toDate != null
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 14,
                                  color: _toDate != null
                                      ? AppColors.primary
                                      : AppColors.textHint),
                              const SizedBox(width: 6),
                              Text(
                                _toDate != null
                                    ? _formatDate(_toDate!)
                                    : 'To date',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _toDate != null
                                      ? AppColors.primary
                                      : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_fromDate != null || _toDate != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: _clearDates,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.dangerSurface,
                            borderRadius: AppRadius.inputRadius,
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.danger),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (_filter != null || _fromDate != null || _toDate != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePadding, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${logs.length} result${logs.length == 1 ? '' : 's'} found',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

              // ── Master Stream Result List View Builder ──
              Expanded(
                child: logs.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded,
                          size: 48, color: AppColors.textHint),
                      const SizedBox(height: AppSpacing.md),
                      Text('No logs found', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: () async {
                    await context
                        .read<ProductProvider>()
                        .loadUserLogs(userId);
                  },
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding:
                    const EdgeInsets.all(AppSpacing.pagePadding),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _LogCard(log: logs[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Filter Chip Widget Component ────────────────────────────────────────────────────────────

class _LogFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _LogFilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: AppRadius.chipRadius,
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Log Analytical Item Entry Card Component ────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  final InventoryLogModel log;
  const _LogCard({required this.log});

  Color get _color {
    switch (log.logType) {
      case LogType.stockIn:    return AppColors.success;
      case LogType.stockOut:   return AppColors.danger;
      case LogType.transfer:   return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (log.logType) {
      case LogType.stockIn:    return Icons.add_circle_outline;
      case LogType.stockOut:   return Icons.remove_circle_outline;
      case LogType.transfer:   return Icons.swap_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.12),
              borderRadius: AppRadius.inputRadius,
            ),
            child: Icon(_icon, color: _color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.productName ?? 'Unknown Product',
                        style: AppTextStyles.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${log.logType == LogType.stockOut ? '-' : '+'}${log.quantity}',
                      style: AppTextStyles.labelMedium.copyWith(color: _color),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  log.logType == LogType.transfer
                      ? '${log.fromWarehouseName} → ${log.toWarehouseName ?? ''}'
                      : log.fromWarehouseName ?? '',
                  style: AppTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (log.note != null && log.note!.isNotEmpty)
                      Expanded(
                        child: Text(log.note!,
                            style: AppTextStyles.bodySmall,
                            overflow: TextOverflow.ellipsis),
                      ),
                    Text(
                      log.createdAt.length > 10
                          ? log.createdAt.substring(0, 10)
                          : log.createdAt,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}