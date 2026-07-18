import re

file_path = 'app/infra/models.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

classes_to_update = ['RoomCategory', 'Room', 'Guest', 'Booking', 'CheckIn', 'CheckOut', 'HousekeepingTask', 'MaintenanceTicket', 'LostAndFound', 'Invoice', 'Payment']

for cls in classes_to_update:
    pattern = r'(class ' + cls + r'\(.*?\):.*?__tablename__\s*=\s*"[^"]+"\n(?:.*?__table_args__\s*=\s*.*?\n)?)'
    replacement = r'\1    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("public.properties.property_id"), nullable=False)\n'
    content = re.sub(pattern, replacement, content, count=1, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated models.py")
