import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';

class RoomGridScreen extends StatefulWidget {
  const RoomGridScreen({super.key});

  @override
  State<RoomGridScreen> createState() => _RoomGridScreenState();
}

class _RoomGridScreenState extends State<RoomGridScreen> {
  String _activeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: _buildFilters(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: _buildGrid(context),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)), // FAB padding
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.signal_wifi_off, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            'Pinesphere Stay',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outlineVariant, width: 1),
              color: AppColors.surfaceContainerHigh,
              image: const DecorationImage(
                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBHeeTDo4rfwkGKaRKckvU6Y0X0GMpXRovvXZGa8Vq1QrWoN8exfXHm1vqIMa-Kzl7quubar_tdpyKVJpJKcyT_iWQibjwRhwT792Unm2K9aCOs4ZwhAvhNTlPECu83pHyoHUN3h9vsC7L6jkGnziycQNSDCxY-aO3JhXV_OUASKR4X0Kpde1d01sSi1MaYxTi_0303K_BITzRVoilPZKBhBCACxHFfNHBclqU6B72WDam4iY11mNRYmQ'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    final filters = ['All', 'Vacant', 'Occupied', 'Cleaning'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isActive = _activeFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () => setState(() => _activeFilter = filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    filter,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isActive ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      delegate: SliverChildListDelegate([
        _buildRoomCard(
          context,
          status: 'Occupied',
          roomNumber: '302',
          type: 'Deluxe Suite',
          price: '\$120/night',
          guestName: 'John Doe',
          guestSub: 'Checkout: Oct 24',
        ),
        _buildRoomCard(
          context,
          status: 'Vacant',
          roomNumber: '105',
          type: 'Twin Room',
          price: '\$85/night',
          buttonLabel: 'BOOK NOW',
        ),
        _buildRoomCard(
          context,
          status: 'Cleaning',
          roomNumber: '212',
          type: 'Standard King',
          price: '\$95/night',
          guestName: 'In progress...',
          guestNameItalic: true,
          guestIcon: Icons.cleaning_services_outlined,
        ),
        _buildRoomCard(
          context,
          status: 'Occupied',
          roomNumber: '401',
          type: 'Penthouse',
          price: '\$450/night',
          guestName: 'Alice Smith',
          guestSub: 'Checkout: Oct 28',
        ),
      ]),
    );
  }

  Widget _buildRoomCard(
    BuildContext context, {
    required String status,
    required String roomNumber,
    required String type,
    required String price,
    String? guestName,
    String? guestSub,
    bool guestNameItalic = false,
    IconData? guestIcon,
    String? buttonLabel,
  }) {
    Color edgeColor;
    Color chipBg;
    Color chipText;

    if (status == 'Occupied') {
      edgeColor = AppColors.error;
      chipBg = AppColors.errorContainer;
      chipText = AppColors.onErrorContainer;
    } else if (status == 'Vacant') {
      edgeColor = AppColors.primary;
      chipBg = AppColors.secondaryContainer;
      chipText = AppColors.onSecondaryContainer;
    } else {
      edgeColor = AppColors.tertiaryContainer;
      chipBg = AppColors.tertiaryFixed;
      chipText = AppColors.onTertiaryFixedVariant;
    }

    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Vertical color bar
          Positioned(
            left: -16,
            top: 24,
            child: Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: edgeColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 8,
                children: [
                  Text(
                    roomNumber,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.onBackground,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: chipText,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 9,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                type,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                price,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
              const Spacer(),
              if (buttonLabel != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    buttonLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.surfaceContainer)),
                  ),
                  child: Row(
                    children: [
                      if (guestIcon != null) ...[
                        Icon(guestIcon, size: 14, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (guestName != null)
                              Text(
                                guestName,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: guestNameItalic ? AppColors.onSurfaceVariant : AppColors.onSurface,
                                      fontWeight: guestNameItalic ? FontWeight.normal : FontWeight.w600,
                                      fontStyle: guestNameItalic ? FontStyle.italic : FontStyle.normal,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (guestSub != null)
                              Text(
                                guestSub,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
