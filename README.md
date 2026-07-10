# Pinesphere Stay

Pinesphere Stay is an enterprise-grade, offline-first Property Management System (PMS) designed for scale, multi-tenancy, and high availability in low-connectivity environments. 

This repository contains both the Flutter mobile/web frontend and the FastAPI Python backend.

## Architecture Highlights
- **Frontend**: Flutter 3.13+, Riverpod (v2+), GoRouter, ObjectBox (Offline-First local DB)
- **Backend**: Python 3.11+, FastAPI, SQLAlchemy 2.0 (Async), PostgreSQL 16 (Row-Level Security for Multi-Tenancy), Redis, MinIO
- **Sync Engine**: Hybrid Logical Clocks (HLC) with Operation-based outbox syncing.

## Documentation

Extensive documentation for developers can be found in the `docs/` directory:
- [Architecture Overview](docs/architecture.md): Deep dive into the Offline-First Sync Engine, ObjectBox, and Riverpod structure.
- [Mobile Setup Guide](docs/setup_flutter.md): Instructions to build and run the Flutter app.
- [Backend Setup Guide](docs/setup_backend.md): Instructions to run the FastAPI PostgreSQL server.

## Directory Structure
- `/pinesphere_backend` - The FastAPI Python backend service
- `/pinesphere_stay` - The Flutter offline-first client application
- `/docs` - Project documentation and setup guides

## Contributing
- Ensure you have read the architecture decisions regarding the sync engine and multi-tenancy before making core changes.
- Always run `dart run build_runner build -d` when modifying Riverpod providers, Freezed models, or ObjectBox entities in the Flutter app.
- Always generate Alembic migrations for any SQLAlchemy model changes in the backend.
