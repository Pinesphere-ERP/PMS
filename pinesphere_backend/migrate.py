import os
import shutil

def replace_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Replacements
    content = content.replace("src.domain.auth", "app.modules.auth")
    content = content.replace("src.domain.property", "app.modules.properties")
    content = content.replace("src.domain.subscription", "app.modules.subscriptions")
    content = content.replace("src.infra.database", "app.database.database")
    content = content.replace("src.core", "app.core")
    content = content.replace("src.api.router", "app.api")
    content = content.replace("src.", "app.")

    with open(filepath, 'w') as f:
        f.write(content)

# Create struct
dirs = [
    "app/modules/auth", "app/modules/properties", "app/modules/subscriptions", "app/modules/sync",
    "app/modules/dashboard", "app/modules/onboarding", "app/modules/rooms", "app/modules/amenities",
    "app/modules/pricing", "app/modules/inventory", "app/modules/documents", "app/modules/payments",
    "app/modules/users", "app/modules/staff", "app/modules/reports", "app/modules/audit",
    "app/database", "app/shared", "app/middleware", "app/uploads"
]
for d in dirs:
    os.makedirs(d, exist_ok=True)

# Move domain models/schemas
for m in ["auth"]:
    if os.path.exists(f"src/domain/{m}/models.py"): shutil.move(f"src/domain/{m}/models.py", f"app/modules/{m}/models.py")
    if os.path.exists(f"src/domain/{m}/schemas.py"): shutil.move(f"src/domain/{m}/schemas.py", f"app/modules/{m}/schemas.py")

if os.path.exists("src/domain/property/models.py"): shutil.move("src/domain/property/models.py", "app/modules/properties/models.py")
if os.path.exists("src/domain/property/schemas.py"): shutil.move("src/domain/property/schemas.py", "app/modules/properties/schemas.py")
if os.path.exists("src/domain/subscription/models.py"): shutil.move("src/domain/subscription/models.py", "app/modules/subscriptions/models.py")
if os.path.exists("src/domain/subscription/schemas.py"): shutil.move("src/domain/subscription/schemas.py", "app/modules/subscriptions/schemas.py")

# Move endpoints
if os.path.exists("src/api/v1/endpoints/auth.py"): shutil.move("src/api/v1/endpoints/auth.py", "app/modules/auth/router.py")
if os.path.exists("src/api/v1/endpoints/property.py"): shutil.move("src/api/v1/endpoints/property.py", "app/modules/properties/router.py")
if os.path.exists("src/api/v1/endpoints/subscription.py"): shutil.move("src/api/v1/endpoints/subscription.py", "app/modules/subscriptions/router.py")
if os.path.exists("src/api/v1/endpoints/sync.py"): shutil.move("src/api/v1/endpoints/sync.py", "app/modules/sync/router.py")

# Move core and infra
if os.path.exists("src/core"): shutil.move("src/core", "app/core")
if os.path.exists("src/infra/database.py"): shutil.move("src/infra/database.py", "app/database/database.py")
if os.path.exists("src/main.py"): shutil.move("src/main.py", "app/main.py")

# Make app/api.py
with open("app/api.py", "w") as f:
    f.write("""from fastapi import APIRouter
from app.modules.auth import router as auth
from app.modules.sync import router as sync
from app.modules.properties import router as property
from app.modules.subscriptions import router as subscription

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(sync.router, prefix="/sync", tags=["Sync Engine"])
api_router.include_router(property.router, prefix="/properties", tags=["Property Management"])
api_router.include_router(subscription.router, prefix="/subscriptions", tags=["Subscription Management"])
""")

# Create __init__.py everywhere
for root, dirs_list, files in os.walk("app"):
    if not os.path.exists(os.path.join(root, "__init__.py")):
        open(os.path.join(root, "__init__.py"), 'a').close()

# Replace file contents
for root, dirs_list, files in os.walk("app"):
    for file in files:
        if file.endswith(".py"):
            replace_in_file(os.path.join(root, file))

for root, dirs_list, files in os.walk("alembic"):
    for file in files:
        if file.endswith(".py"):
            replace_in_file(os.path.join(root, file))

if os.path.exists("alembic.ini"):
    replace_in_file("alembic.ini")

shutil.rmtree("src", ignore_errors=True)
print("Migration done")
