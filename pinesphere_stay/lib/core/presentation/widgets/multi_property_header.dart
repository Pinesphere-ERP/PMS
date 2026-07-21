import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/core/auth/session_context.dart';
import 'package:pinesphere_stay/core/presentation/widgets/property_switcher_widget.dart';

class MultiPropertyHeader extends ConsumerWidget
    implements PreferredSizeWidget {
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const MultiPropertyHeader({
    super.key,
    this.leading,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionContextProvider);
    final hasMultipleProperties = session.accessibleProperties.length > 1;

    return AppBar(
      leading: leading,
      title: hasMultipleProperties
          ? const PropertySwitcherWidget()
          : Text(
              session.activeProperty?.propertyName ?? 'Pinesphere Stay',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
      centerTitle: false,
      actions: actions,
      bottom: bottom,
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
