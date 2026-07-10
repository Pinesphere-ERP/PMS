// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kpi_aggregation_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(kpiAggregationService)
final kpiAggregationServiceProvider = KpiAggregationServiceProvider._();

final class KpiAggregationServiceProvider
    extends
        $FunctionalProvider<
          KpiAggregationService,
          KpiAggregationService,
          KpiAggregationService
        >
    with $Provider<KpiAggregationService> {
  KpiAggregationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kpiAggregationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kpiAggregationServiceHash();

  @$internal
  @override
  $ProviderElement<KpiAggregationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  KpiAggregationService create(Ref ref) {
    return kpiAggregationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KpiAggregationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KpiAggregationService>(value),
    );
  }
}

String _$kpiAggregationServiceHash() =>
    r'c479c08f2dc6e08fe09a1298580e728e176a50e8';

/// Provides the KpiAggregationService singleton.

@ProviderFor(kpiService)
final kpiServiceProvider = KpiServiceProvider._();

/// Provides the KpiAggregationService singleton.

final class KpiServiceProvider
    extends
        $FunctionalProvider<
          KpiAggregationService,
          KpiAggregationService,
          KpiAggregationService
        >
    with $Provider<KpiAggregationService> {
  /// Provides the KpiAggregationService singleton.
  KpiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kpiServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kpiServiceHash();

  @$internal
  @override
  $ProviderElement<KpiAggregationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  KpiAggregationService create(Ref ref) {
    return kpiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KpiAggregationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KpiAggregationService>(value),
    );
  }
}

String _$kpiServiceHash() => r'56ec52be0db2b08a92804d2b0f1e3b535e429f19';

/// Stream provider: emits today's KPI snapshot (or null) reactively.
/// Bind to ObjectBox so the UI re-renders on every local mutation.

@ProviderFor(todaysKpiStream)
final todaysKpiStreamProvider = TodaysKpiStreamFamily._();

/// Stream provider: emits today's KPI snapshot (or null) reactively.
/// Bind to ObjectBox so the UI re-renders on every local mutation.

final class TodaysKpiStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<KpiSnapshotEntity?>,
          KpiSnapshotEntity?,
          Stream<KpiSnapshotEntity?>
        >
    with
        $FutureModifier<KpiSnapshotEntity?>,
        $StreamProvider<KpiSnapshotEntity?> {
  /// Stream provider: emits today's KPI snapshot (or null) reactively.
  /// Bind to ObjectBox so the UI re-renders on every local mutation.
  TodaysKpiStreamProvider._({
    required TodaysKpiStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'todaysKpiStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$todaysKpiStreamHash();

  @override
  String toString() {
    return r'todaysKpiStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<KpiSnapshotEntity?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<KpiSnapshotEntity?> create(Ref ref) {
    final argument = this.argument as String;
    return todaysKpiStream(ref, propertyId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TodaysKpiStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$todaysKpiStreamHash() => r'ef78b805d2d9be5c6d0662b36d2b26b1a2f4cc64';

/// Stream provider: emits today's KPI snapshot (or null) reactively.
/// Bind to ObjectBox so the UI re-renders on every local mutation.

final class TodaysKpiStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<KpiSnapshotEntity?>, String> {
  TodaysKpiStreamFamily._()
    : super(
        retry: null,
        name: r'todaysKpiStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream provider: emits today's KPI snapshot (or null) reactively.
  /// Bind to ObjectBox so the UI re-renders on every local mutation.

  TodaysKpiStreamProvider call({required String propertyId}) =>
      TodaysKpiStreamProvider._(argument: propertyId, from: this);

  @override
  String toString() => r'todaysKpiStreamProvider';
}
