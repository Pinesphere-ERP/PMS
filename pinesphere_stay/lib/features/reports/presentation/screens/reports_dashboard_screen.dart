import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';

class ReportsDashboardScreen extends StatelessWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildMetricsGrid(context),
                  const SizedBox(height: 16),
                  _buildRevenueGraph(context),
                  const SizedBox(height: 16),
                  _buildOccupancyDonut(context),
                  const SizedBox(height: 16),
                  _buildTopRooms(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildExportBar(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.primary),
        onPressed: () {},
      ),
      title: Text(
        'Pinesphere Stay',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceVariant,
              border: Border.all(color: AppColors.outlineVariant),
              image: const DecorationImage(
                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDx5PwNl4ky0Z60FfYnZZLj7RuYefbggaSAv4b7_KUmA9r5SbS7vQUFkaPjEaoSpXm7zuLyhoWZTDbPTvtKBoF-DvbhqSNIHudyIjlhWtU7Zftns2kAi8Z8EG9Ys3yCoEsH4nvXo2Rvl4sKj-n0g_s1fp8uOLF8gJ2ad9yLJggo3e9YCmHENNcIXN1HgBAiwXB-bo90efu6LPUTUQU5NKtUslQUYqXTo2noG9TCq7bmXvYfFErvg5HI3Q'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports Overview',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Performance data for March 1 - March 7, 2024',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard(context, Icons.payments_outlined, AppColors.primary, "Today's Collection", '\$1,240'),
        _buildMetricCard(context, Icons.trending_up, AppColors.onPrimaryContainer, 'Monthly Revenue', '\$42,850', bg: AppColors.primaryContainer, textColor: AppColors.onPrimaryContainer),
        _buildMetricCard(context, Icons.bed_outlined, AppColors.secondary, 'Avg Occupancy', '82%'),
        _buildMetricCard(context, Icons.pending_actions_outlined, AppColors.error, 'Pending Payments', '\$950'),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, IconData icon, Color iconColor, String title, String value, {Color? bg, Color? textColor}) {
    return BentoCard(
      backgroundColor: bg ?? AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: (textColor ?? AppColors.onSurfaceVariant).withOpacity(0.8),
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: textColor ?? iconColor,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueGraph(BuildContext context) {
    return BentoCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.onSurface),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Weekly',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBar(context, 'M', 0.6),
                _buildBar(context, 'T', 0.45),
                _buildBar(context, 'W', 0.85),
                _buildBar(context, 'T', 0.7),
                _buildBar(context, 'F', 0.55),
                _buildBar(context, 'S', 0.95),
                _buildBar(context, 'S', 0.8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, String day, double percentage) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: percentage,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            day,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyDonut(BuildContext context) {
    return BentoCard(
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  color: AppColors.surfaceContainerHigh,
                ),
                CircularProgressIndicator(
                  value: 0.82,
                  strokeWidth: 12,
                  color: AppColors.secondary,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '82%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.onSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Occupancy Rate',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  '42 of 51 units are currently occupied.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildLegendItem(context, AppColors.secondary, 'Occupied'),
                    const SizedBox(width: 16),
                    _buildLegendItem(context, AppColors.surfaceContainerHigh, 'Vacant'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildTopRooms(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Performing Units',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.onSurface),
            ),
            Row(
              children: [
                Text(
                  'View All',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary),
                ),
                const Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRoomRow(context, Icons.apartment, 'Room 401', 'Penthouse Suite', '\$12.4k', '98% Occ.'),
        const SizedBox(height: 12),
        _buildRoomRow(context, Icons.hotel, 'Room 302', 'Deluxe Garden View', '\$9.8k', '94% Occ.'),
        const SizedBox(height: 12),
        _buildRoomRow(context, Icons.holiday_village, 'Cabin 12', 'Premium Forest Lodge', '\$8.2k', '89% Occ.'),
      ],
    );
  }

  Widget _buildRoomRow(BuildContext context, IconData icon, String title, String subtitle, String rev, String occ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.onSurface)),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rev, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  occ,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.picture_as_pdf, size: 20),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.table_chart, size: 20),
                label: const Text('Export Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryContainer,
                  foregroundColor: AppColors.onSecondaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
