# 18. Developer Guide

## Prerequisites

| Tool | Version | Required for |
|------|---------|-------------|
| Python | 3.12+ | Backend |
| Node.js | 18+ | Frontend |
| Flutter SDK | 3.12+ | Mobile app |
| Git | Any | All |
| PostgreSQL | 14+ | Production DB |
| SQLite | Built-in | Dev DB (auto-used) |

---

## Cloning the Repository

```bash
git clone <repo_url>
cd PMS
```

---

## Backend Development

### First-time Setup

```bash
cd pinesphere_backend

# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy .env template
copy .env.example .env

# Edit .env — set DATABASE_URL for local SQLite:
# DATABASE_URL=sqlite+aiosqlite:///./pinesphere.db
# ALEMBIC_DATABASE_URL=sqlite:///./pinesphere.db
# SECRET_KEY=any-long-random-string-here

# Initialize database (creates all tables)
python init_db.py

# Seed initial Super Admin user
python seed_admin.py
# Creates: admin@pinesphere.in / admin123

# Start dev server
uvicorn app.main:app --reload --port 8000
```

### API Documentation
- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

### Adding a New Module

1. Create directory: `app/modules/new_module/`
2. Create files: `__init__.py`, `router.py`, `schemas.py`, `service.py`
3. Add router import to `app/api.py`
4. Add table models to `app/infra/models.py`
5. Run `alembic revision --autogenerate -m "add_new_module"`
6. Run `alembic upgrade head`

### Adding a New Database Column

1. Edit the model in `app/infra/models.py`
2. Run `alembic revision --autogenerate -m "description"`
3. Review the generated migration in `alembic/versions/`
4. Run `alembic upgrade head`

**SQLite Note:** SQLite does not support `ALTER TABLE ADD COLUMN` with constraints. For complex migrations on dev, delete `pinesphere.db` and re-run `init_db.py`.

---

## Frontend Development

### Setup

```bash
cd web/admin

npm install
npm run dev
```

Portal runs at: http://localhost:5173

### Environment Variables

Create `web/admin/.env.local`:
```
VITE_API_BASE_URL=http://localhost:8000/api/v1
```

### Adding a New Page

1. Create `src/pages/ModuleName/PageName.jsx`
2. Add route in `src/App.jsx`:
   ```jsx
   <Route path="your/path" element={<PageName />} />
   ```
3. Add nav link in `src/layouts/AdminLayout.jsx`
4. Use `fetchAPI()` for API calls

### Code Style

- Functional components with hooks
- No class components
- Vanilla CSS only (no Tailwind)
- `fetchAPI()` for all HTTP calls
- Error handling with `try/catch` around every API call
- Loading state with `useState(true)` before fetch, `false` after

---

## Mobile Development

### Setup

```bash
cd pinesphere_stay

flutter pub get
```

### Code Generation

Run after any model or provider changes:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:
- `*.g.dart` files (ObjectBox, Riverpod, JSON)
- `*.freezed.dart` files (Freezed models)

### Connecting to Local Backend

```bash
# Android Emulator
flutter run --dart-define=API_URL=http://10.0.2.2:8000/api/v1

# Physical Android device (same WiFi)
flutter run --dart-define=API_URL=http://192.168.X.X:8000/api/v1

# Windows desktop
flutter run -d windows --dart-define=API_URL=http://localhost:8000/api/v1
```

### Adding a New Feature

1. Create directory: `lib/features/feature_name/`
2. Create subdirectories: `data/`, `domain/`, `presentation/`
3. Define ObjectBox model in `data/models/`
4. Run code generation
5. Create datasource (API calls)
6. Create repository
7. Create Riverpod provider
8. Create screen widget
9. Add route in `lib/app/app.dart`

### Flutter Analyze

```bash
flutter analyze
```

Common issues:
- `.g.dart` file missing: Run code generation
- Undefined provider: Check riverpod_generator annotations
- Null safety errors: Handle nullable types explicitly

---

## Common Development Tasks

### Reset Local Database

```bash
cd pinesphere_backend
rm pinesphere.db
python init_db.py
python seed_admin.py
```

### Run Backend Tests

```bash
cd pinesphere_backend
pytest
```

### Test API Manually (cURL)

```bash
# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@pinesphere.in","password":"admin123"}'

# Use the token
TOKEN=<token_from_login>
curl http://localhost:8000/api/v1/properties \
  -H "Authorization: Bearer $TOKEN"
```

---

## Troubleshooting

### Backend Issues

| Error | Cause | Fix |
|-------|-------|-----|
| `name 'current_user' is not defined` | Using `current_user` without injecting `get_current_user` dependency | Add `current_user: User = Depends(get_current_user)` to route function |
| `column "floor" does not exist` | Migration not applied | Run `alembic upgrade head` or manually `ALTER TABLE rooms ADD COLUMN floor VARCHAR(10)` |
| `Input should be a valid UUID` | String passed instead of UUID | Check that IDs come from database, not placeholder values |
| `402 Payment Required` | Subscription expired | Check `subscriptions` table, update `expiry_date` |
| `401 Unauthorized` | Token expired or revoked | Re-login to get new token |

### Frontend Issues

| Error | Cause | Fix |
|-------|-------|-----|
| `Failed to load data` | API request failing | Check DevTools Network tab for specific error |
| `401 Unauthorized` | Token expired | Clear localStorage, re-login |
| White page | JavaScript error | Check browser console |
| CORS error | Backend CORS config | Check `allow_origins` in `main.py` |

### Mobile Issues

| Error | Cause | Fix |
|-------|-------|-----|
| `uri_has_not_been_generated` | Generated file missing | Run `flutter pub run build_runner build` |
| `undefined_identifier` | Provider not generated | Check `@riverpod` annotation, regenerate |
| Cannot connect to backend | Wrong API URL | Check `--dart-define=API_URL=...` |
| App crashes on startup | ObjectBox schema mismatch | Uninstall app, run `build_runner build`, reinstall |

---

## Code Standards

### Backend
- Async functions throughout (`async def`, `await`)
- Pydantic schemas for all request/response
- `StandardResponse` for all API responses
- Audit log on all mutations
- Type hints on all function parameters
- Error handling: raise `HTTPException` with specific status codes

### Frontend
- Destructure all hook returns
- Always handle loading, error, and empty states
- Use `fetchAPI()` wrapper (never raw fetch)
- Responsive CSS only

### Mobile (Flutter)
- Riverpod for all state
- Clean Architecture per feature
- No hardcoded strings (use constants)
- Handle offline and online states separately

---

## Cross-References

- Deployment: [17-deployment.md](./17-deployment.md)
- Architecture: [02-architecture.md](./02-architecture.md)
- All modules: [05-backend.md](./05-backend.md)
