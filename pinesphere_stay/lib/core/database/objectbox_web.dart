import 'package:pinesphere_stay/objectbox.g.dart';

class ObjectBox {
  late final Store store;

  ObjectBox._create(this.store);

  static Future<ObjectBox> create() async {
    // Return dummy web implementation
    return ObjectBox._create(Store());
  }
}
