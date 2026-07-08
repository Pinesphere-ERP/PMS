# Pinesphere Stay

Pinesphere Stay is an enterprise-grade, offline-first Property Management System (PMS) designed for scale, multi-tenancy, and high availability in low-connectivity environments. 

This repository contains both the Flutter mobile/web frontend and the FastAPI Python backend.

## Architecture Highlights
- **Frontend**: Flutter 3.13+, Riverpod (v2+), GoRouter, ObjectBox (Offline-First local DB)
- **Backend**: Python 3.11+, FastAPI, SQLAlchemy 2.0 (Async), PostgreSQL 16 (Row-Level Security for Multi-Tenancy), Redis, MinIO
- **Sync Engine**: Hybrid Logical Clocks (HLC) with Operation-based outbox syncing.

## Getting Started

To get the project running locally, please follow the detailed setup guides in the `docs/` folder:

1. **[Backend Setup Guide](docs/setup_backend.md)** - Setting up Docker (Postgres, Redis, MinIO) and the FastAPI environment.
2. **[Flutter Frontend Setup Guide](docs/setup_flutter.md)** - Setting up Dart, Flutter, and running the app for Mobile and Web.

## Directory Structure
- `/pinesphere_backend` - The FastAPI Python backend service
- `/pinesphere_stay` - The Flutter offline-first client application
- `/docs` - Project documentation and setup guides

## Contributing
- Ensure you have read the architecture decisions regarding the sync engine and multi-tenancy before making core changes.
- Always run `dart run build_runner build -d` when modifying Riverpod providers, Freezed models, or ObjectBox entities in the Flutter app.
- Always generate Alembic migrations for any SQLAlchemy model changes in the backend.
