import 'package:live_shopping/core/theme/bazzar_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_shopping/core/widgets/dashboard_card.dart';
import 'package:live_shopping/features/seller_dashboard/presentation/widgets/seller_app_drawer.dart';
import '../providers/dashboard_provider.dart';
import '../../../auth/presentation/widgets/logout_confirmation_dialog.dart';
import '../../../products/presentation/pages/add_product_page.dart';
import '../../../products/presentation/pages/categories_list_page.dart';

class SellerDashboardPage extends ConsumerStatefulWidget {
  final String sellerId;
  const SellerDashboardPage({super.key, required this.sellerId});

  @override
  ConsumerState<SellerDashboardPage> createState() =>
      _SellerDashboardPageState();
}

class _SellerDashboardPageState extends ConsumerState<SellerDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  Future<void> _signOut({bool closeDrawer = false}) async {
    final navContext = context;
    await confirmSignOut(navContext, ref, closeDrawer: closeDrawer);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }

    if (index == 1) {
      // Index 1 correspond à 'Produits'
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoriesListPage(sellerId: widget.sellerId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider(widget.sellerId));
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: BazzarColors.surface,
        foregroundColor: BazzarColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 76,
        titleSpacing: 20,
        shape: const Border(bottom: BorderSide(color: BazzarColors.border)),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour 👋',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Miantsena Store',
              style: TextStyle(
                color: BazzarColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: 0,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: BazzarColors.ink,
            ),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () => _signOut(),
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Déconnexion',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: SellerAppDrawer(sellerId: widget.sellerId),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            statsAsync.when(
              data: (stats) => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildKPI(
                    'Réservations',
                    '${stats['reservations']}',
                    const Color(0xFF3B82F6),
                    Icons.calendar_today_rounded,
                  ),
                  _buildKPI(
                    'Produits',
                    '${stats['products']}',
                    const Color(0xFF8B5CF6),
                    Icons.inventory_2_rounded,
                  ),
                  _buildKPI(
                    'Ventes',
                    '0',
                    const Color(0xFF10B981),
                    Icons.trending_up_rounded,
                  ),
                  _buildKPI(
                    'Solde',
                    '0€',
                    const Color(0xFFF59E0B),
                    Icons.account_balance_wallet_rounded,
                  ),
                ],
              ),
              loading: () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Erreur: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _buildSectionHeader('Raccourcis'),
            const SizedBox(height: 14),
            _buildShortcuts(),
            const SizedBox(height: 28),
            _buildSectionHeader('Commandes récentes'),
            const SizedBox(height: 14),
            _buildRecentOrders(),
            const SizedBox(height: 28),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_rounded),
              label: 'Produits',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Commandes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profil',
            ),
          ],
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: BazzarColors.ink,
        letterSpacing: 0,
      ),
    );
  }

  Widget _buildKPI(String title, String value, Color color, IconData icon) {
    return DashboardCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: BazzarColors.ink,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcuts() {
    return Row(
      children: [
        Expanded(
          child: _shortcutItem(Icons.add_box_rounded, 'Ajouter', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddProductPage(sellerId: widget.sellerId),
              ),
            );
          }),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _shortcutItem(Icons.local_offer_rounded, 'Promos', () {}),
        ),
        const SizedBox(width: 12),
        Expanded(child: _shortcutItem(Icons.bar_chart_rounded, 'Stats', () {})),
      ],
    );
  }

  Widget _shortcutItem(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: Colors.deepPurple.withValues(alpha: 0.05),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.deepPurple, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BazzarColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    return DashboardCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (ctx, i) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (ctx, i) => ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            child: const Icon(Icons.person_rounded, color: Colors.grey),
          ),
          title: const Text(
            'Client Test',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            'Commande #1234',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          trailing: const Text(
            '25.00€',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: BazzarColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
