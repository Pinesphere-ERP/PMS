// Conditional export for ObjectBox annotations
export 'package:objectbox/objectbox.dart'
    if (dart.library.js_interop) 'obx_annotations_stub.dart';
