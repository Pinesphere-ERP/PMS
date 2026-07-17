import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinesphere_stay/core/theme/app_colors.dart';
import 'package:pinesphere_stay/features/portal/presentation/screens/portal_login_screen.dart';

class GuestDashboardScreen extends ConsumerStatefulWidget {
  const GuestDashboardScreen({super.key});

  @override
  ConsumerState<GuestDashboardScreen> createState() => _GuestDashboardScreenState();
}

class _GuestDashboardScreenState extends ConsumerState<GuestDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final guestName = ref.watch(guestNameProvider) ?? 'Guest';
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Welcome, $guestName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(guestTokenProvider.notifier).setToken(null);
              context.go('/portal/login');
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _PortalFolioTab(),
          _PortalRoomServiceTab(),
          _PortalHelpTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'My Folio',
          ),
          NavigationDestination(
            icon: Icon(Icons.room_service_outlined),
            selectedIcon: Icon(Icons.room_service),
            label: 'Room Service',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: 'Help & Services',
          ),
        ],
      ),
    );
  }
}

class _PortalFolioTab extends ConsumerWidget {
  const _PortalFolioTab();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Current Stay Folio', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.outlineVariant)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFolioItem('Room Rate (2 nights)', '₹ 4,000'),
                const Divider(),
                _buildFolioItem('Room Service (Dinner)', '₹ 850'),
                const Divider(),
                _buildFolioItem('GST (12%)', '₹ 582'),
                const Divider(thickness: 2),
                _buildFolioItem('Total Balance', '₹ 5,432', isBold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Pay Now / Checkout'),
        )
      ],
    );
  }

  Widget _buildFolioItem(String label, String amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(amount, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _PortalRoomServiceTab extends ConsumerWidget {
  const _PortalRoomServiceTab();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = [
      {'name': 'Club Sandwich', 'price': '₹ 250'},
      {'name': 'Paneer Tikka', 'price': '₹ 320'},
      {'name': 'Cold Coffee', 'price': '₹ 150'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: menu.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return const Padding(padding: EdgeInsets.only(bottom: 24), child: Text('Room Service Menu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
        final item = menu[index - 1];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.outlineVariant)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(item['name']!),
            subtitle: Text(item['price']!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            trailing: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['name']} added to order!')));
              },
              child: const Text('Order'),
            ),
          ),
        );
      },
    );
  }
}

class _PortalHelpTab extends ConsumerWidget {
  const _PortalHelpTab();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = [
      {'icon': Icons.cleaning_services, 'label': 'Clean Room'},
      {'icon': Icons.dry_cleaning, 'label': 'Extra Towels'},
      {'icon': Icons.water_drop, 'label': 'Water Bottles'},
      {'icon': Icons.build, 'label': 'Maintenance'},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Request Service', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: services.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${services[index]['label']} requested!')));
                  },
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.outlineVariant)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(services[index]['icon'] as IconData, size: 48, color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(services[index]['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
