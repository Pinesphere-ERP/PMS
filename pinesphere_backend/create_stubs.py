import os

modules = ["auth", "properties", "subscriptions", "sync"]

for mod in modules:
    os.makedirs(f"app/modules/{mod}", exist_ok=True)
    
    with open(f"app/modules/{mod}/router.py", "w") as f:
        f.write(f"""from fastapi import APIRouter
router = APIRouter()

@router.get("/")
def get_{mod}():
    return {{"status": "{mod} stub"}}
""")

    with open(f"app/modules/{mod}/__init__.py", "w") as f:
        f.write("from .router import router\n")

print("Stubs created.")
