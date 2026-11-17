# StockNest

An offline-first Flutter app for managing inventory across multiple warehouses, built for small businesses, daycares, small offices, and organized homes.

> Final project for *Mobile Application Design and Development* (CEN306), Istanbul Topkapı University (2026).

**[Demo video](https://youtu.be/IO35_uN1T3Q)** · **[Download APK](https://drive.google.com/file/d/14zBd1PZB13dd_l8UwSzAWXTa03YkCAgt/view?usp=sharing)**

<!-- TODO: add 2-3 screenshots, e.g. ![Home](screenshots/home.png) -->

## The Problem

Small organizations often track supplies in spreadsheets or in enterprise software that is too complex, needs paid cloud plans, and needs constant internet. StockNest runs fully on the device and shows exactly where each item is stored, down to rooms, shelves, and bins.

## Features

- **Nested warehouses:** create root warehouses and unlimited sub-warehouses.
- **Product catalog:** unique SKUs, units, and system or custom categories (with emoji tags).
- **Stock operations:** Stock-In, Stock-Out, and transfers between warehouses, protected by atomic database transactions so balances never end up inconsistent.
- **Low-stock indicators** and a home dashboard with summary counts.
- **Audit logs** with date and operation filters, and **PDF report export**.
- **Local authentication** with SHA-256 hashed passwords.

## Architecture

A four-layer clean architecture:

| Layer | Responsibility | Examples |
|-------|----------------|----------|
| Presentation | Screens and reusable widgets | `DistributeScreen`, `AppTextField` |
| State management | `ChangeNotifier` providers | `WarehouseProvider`, `ProductProvider` |
| Repository | Single source of truth, transactions | `WarehouseRepository` |
| Data | DAOs, models, SQLite | `WarehouseDao`, `DatabaseHelper` |

```
lib/
├── core/        # theme, reusable widgets
├── data/        # dao, database, models, repositories
├── domain/      # providers
└── ui/          # screens by feature
```

## Tech Stack

Flutter, Dart, SQLite (`sqflite`), Provider, `go_router`, `shared_preferences`, `pdf` and `printing`.

## Getting Started

```bash
git clone https://github.com/asmaatya205-del/StockNest-App.git
cd StockNest-App
flutter pub get
flutter run
```

## Testing

Tested manually on Android emulators and physical devices: warehouse creation, stock transfers, cascade deletion, form validation, duplicate SKU blocking, and data persistence after restarting the app.

## Limitations and Future Work

- Data is stored locally on one device (no cloud sync yet).
- No undo for transfers; mistakes are fixed with an opposite transfer.
- Planned: Firebase sync, low-stock push notifications, database indexes for faster search, and dashboard charts.

## Author

**Asma Atiah**, Computer Engineering, Istanbul Topkapı University
[LinkedIn](https://www.linkedin.com/in/asma-atiah-1442a7317) · asmaatya205@gmail.com
