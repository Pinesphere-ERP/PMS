with open('app/infra/models.py', 'r', encoding='utf-8') as f:
    content = f.read()

if "RoomCategory = RoomType" not in content:
    content += "\n\nRoomCategory = RoomType\n"
    content += "Room.room_category_id = Room.room_type_id\n"
    content += "RoomCategory.room_category_id = RoomType.id\n"
    
    with open('app/infra/models.py', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Patched models.py")
