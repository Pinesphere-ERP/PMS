from app.modules.properties.schemas import PropertyCreateInput

try:
    obj = PropertyCreateInput(**{
        "owner_name": "Alice Smith",
        "business_name": "Alice Luxury Hotels",
        "property_name": "The Grand Alice"
    })
    print("Success:", obj)
except Exception as e:
    print("Failed:", e)
