import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logger.dart';

base class AppProviderObserver extends ProviderObserver {
  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    AppLogger.d('Provider ${context.provider.name ?? context.provider.runtimeType} initialized with $value');
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    AppLogger.d('Provider ${context.provider.name ?? context.provider.runtimeType} updated from $previousValue to $newValue');
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    AppLogger.d('Provider ${context.provider.name ?? context.provider.runtimeType} disposed');
  }
}
