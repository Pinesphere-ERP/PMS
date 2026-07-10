# Pinesphere Stay - Architecture Overview

This document outlines the core architecture of the **Pinesphere Stay** project, encompassing the mobile application, the offline-first database synchronization engine, and the backend infrastructure.

## 1. System Overview

Pinesphere Stay is an enterprise-grade Property Management System (PMS) built with an **Offline-First** philosophy. Hotel operations (housekeeping, front desk, etc.) must continue functioning seamlessly even in areas with zero network connectivity (e.g., concrete basements, remote cabins). 

To achieve this, the architecture relies on a local database embedded directly within the mobile application that acts as the single source of truth for the UI. A background Sync Engine handles data reconciliation with a remote backend once network connectivity is restored.

---

## 2. Mobile Implementation (Flutter)

The mobile application is built using **Flutter** and is structured to handle high complexity while maintaining high performance.

### State Management & Dependency Injection
- **Riverpod (v2+)**: Used extensively for reactive state management and dependency injection. Riverpod isolates business logic from the UI and safely scopes providers (like network clients, database stores, and repositories).
- **Code Generation**: Utilizing `riverpod_generator`, we generate strongly typed providers, reducing boilerplate and preventing common lifecycle errors.

### UI / UX Architecture
- **Bento Design System**: The UI utilizes a modern "Bento Box" aesthetic. Information is heavily modularized into soft-rounded, card-like containers, avoiding generic dashboard layouts.
- **Micro-Animations**: Uses subtle haptics (`HapticFeedback`) and explicit animations (e.g., the shake animation on an incorrect PIN) to provide a premium tactile feel.
- **Feature-First Structure**: The `lib` folder is organized by feature (e.g., `features/auth`, `features/dashboard`, `features/rooms`). Inside each feature, code is strictly divided into:
  - `presentation/` (Screens, Widgets, Providers)
  - `domain/` (Entities, Models, Business Rules)
  - `data/` (Repositories, Sync logic)

### Navigation
- **GoRouter**: Manages complex routing schemas, including Deep Linking and guarded routes.
- **StatefulShellRoute**: Used to preserve navigation state across bottom navigation tabs. When navigating from "Dashboard" to "Rooms" and back, the exact scroll position and state are maintained without rebuilding the element tree.
- **RouterNotifier**: A custom implementation that wraps Riverpod's `authProvider` to securely trigger router redirects (like kicking an unauthenticated user to the login screen) without crashing or tearing down the widget tree.

---

## 3. Database Architecture

Because the app is offline-first, data exists in two places: the local device and the cloud server.

### Local Database (Mobile) - ObjectBox
- **Why ObjectBox?** ObjectBox is an ultra-fast NoSQL local database written in C/C++. It vastly outperforms SQLite in read/write speeds, which is critical when a device comes back online and suddenly needs to ingest hundreds of mutations instantly.
- **Entities**: Data is stored as annotated dart classes (`@Entity()`).
  - `RoomEntity`: Stores local room data.
  - `SyncQueueEntity`: Stores offline mutations (e.g., "Change Room 102 Status to Cleaning"). 
- **Code Gen**: `build_runner` compiles these entities into optimal bindings (`objectbox.g.dart`).

### Remote Database (Cloud) - PostgreSQL
- **Backend Stack**: The backend is powered by **FastAPI** (Python) and **SQLAlchemy** acting as the ORM.
- **Data Integrity**: PostgreSQL acts as the ultimate long-term storage and central node for resolving conflicts between multiple devices (e.g., the receptionist's tablet and a housekeeper's phone).

---

## 4. The Offline-First Sync Engine

The core innovation of Pinesphere Stay is the Sync Engine, designed to handle asynchronous data without UI loading spinners.

### How it Works (The Outbox Pattern)
1. **Local Mutation**: When a user changes a room's status, the UI immediately writes the update to the local `RoomEntity` in ObjectBox. The UI updates instantly.
2. **Queueing**: Simultaneously, a `SyncQueueEntity` is created containing the mutation payload (e.g., `OPERATION: UPDATE`, `ENTITY: ROOM`, `ID: 102`) and pushed to the local ObjectBox queue.
3. **Connectivity Listener**: The `SyncService` uses `connectivity_plus` to monitor the device's internet connection in the background.
4. **Push**: When a connection is detected, the `SyncService` pulls all pending `SyncQueueEntity` records and POSTs them to the backend (`/sync/push`).
5. **Acknowledge**: If the backend successfully applies them to PostgreSQL, it returns a 200 OK, and the mobile app deletes those records from its local `SyncQueue`.
6. **Pull**: The mobile app then calls `/sync/pull` to retrieve any changes made by *other* devices while this device was offline.

### Conflict Resolution
- **Hybrid Logical Clocks (HLC)**: Every mutation is tagged with an HLC timestamp. If two devices modify the same room while offline, the backend uses these HLCs to determine the exact sequence of events, ensuring absolute consistency regardless of physical network delays.
