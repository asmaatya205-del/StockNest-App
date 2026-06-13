
enum LogType {
  stockIn,
  stockOut,
  transfer,
}

extension LogTypeExtension on LogType {
  String get label {
    switch (this) {
      case LogType.stockIn:     return 'Stock In';
      case LogType.stockOut:    return 'Stock Out';
      case LogType.transfer:    return 'Transfer';
    }
  }

  String get value {
    switch (this) {
      case LogType.stockIn:     return 'stock_in';
      case LogType.stockOut:    return 'stock_out';
      case LogType.transfer:    return 'transfer';
    }
  }

  static LogType fromString(String v) {
    switch (v) {
      case 'stock_in':    return LogType.stockIn;
      case 'stock_out':   return LogType.stockOut;
      case 'transfer':    return LogType.transfer;
      default:            return LogType.stockIn; // Fallback safe default after removing adjustment
    }
  }
}

class InventoryLogModel {
  final int? id;
  final int productId;
  final int fromWarehouseId;
  final int? toWarehouseId;
  final double quantity;
  final LogType logType;
  final String? note;
  final int userId;
  final String createdAt;

  final String? productName;
  final String? fromWarehouseName;
  final String? toWarehouseName;

  const InventoryLogModel({
    this.id,
    required this.productId,
    required this.fromWarehouseId,
    this.toWarehouseId,
    required this.quantity,
    required this.logType,
    this.note,
    required this.userId,
    required this.createdAt,
    this.productName,
    this.fromWarehouseName,
    this.toWarehouseName,
  });

  Map<String, dynamic> toMap() => {
    'id':                id,
    'product_id':        productId,
    'from_warehouse_id': fromWarehouseId,
    'to_warehouse_id':   toWarehouseId,
    'quantity':          quantity,
    'log_type':          logType.value,
    'note':              note,
    'user_id':           userId,
    'created_at':        createdAt,
  };

  factory InventoryLogModel.fromMap(Map<String, dynamic> m) => InventoryLogModel(
    id:                m['id'],
    productId:         m['product_id'],
    fromWarehouseId:   m['from_warehouse_id'],
    toWarehouseId:     m['to_warehouse_id'],
    quantity:          (m['quantity'] as num).toDouble(),
    logType:           LogTypeExtension.fromString(m['log_type']),
    note:              m['note'],
    userId:            m['user_id'],
    createdAt:         m['created_at'],
    productName:       m['product_name'],
    fromWarehouseName: m['from_warehouse_name'],
    toWarehouseName:   m['to_warehouse_name'],
  );
}