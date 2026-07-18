import 'package:pinesphere_stay/objectbox.g.dart';

class ObjectBox {
  late final Store store;

  ObjectBox._create(this.store);

  static Future<ObjectBox> create() async {
    throw UnimplementedError('ObjectBox is not supported on web');
  }
}
