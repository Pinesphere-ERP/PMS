// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(roomService)
final roomServiceProvider = RoomServiceProvider._();

final class RoomServiceProvider
    extends $FunctionalProvider<RoomService, RoomService, RoomService>
    with $Provider<RoomService> {
  RoomServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomServiceHash();

  @$internal
  @override
  $ProviderElement<RoomService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RoomService create(Ref ref) {
    return roomService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoomService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoomService>(value),
    );
  }
}

String _$roomServiceHash() => r'7d26105ad5a8a9b3ea7c55e4c0b064faaddafa0b';
