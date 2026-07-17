// ObjectBox annotation stubs for Web compilation
class Entity { const Entity(); }
class Id { const Id({int type = 0, bool assignable = false}); }
class Unique { const Unique({int? onConflict}); }
class Property { const Property({int? type, String? uid}); }
class Transient { const Transient(); }
class Index { const Index({int? type}); }
class Backlink { const Backlink([String? to]); }
class Uid { const Uid(int uid); }
class HnswIndex { const HnswIndex({int? dimensions}); }
class Sync { const Sync(); }

// Dummy enums and constants
class PropertyType {
  static const int date = 5;
  static const int dateNano = 12;
  static const int byteVector = 23;
  static const int stringVector = 30;
  static const int char = 8;
}

class ConflictStrategy {
  static const int replace = 1;
  static const int fail = 2;
}

class IdType {
  static const int assignable = 1;
}
