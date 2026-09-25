import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:live_shopping/features/orders/domain/entities/reservation.dart';
import 'package:live_shopping/features/orders/presentation/pages/reservation_details_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/seller_dashboard/presentation/pages/seller_dashboard_screen.dart';
import '../../features/seller_dashboard/presentation/pages/products/seller_product_list_screen.dart';
import '../../features/seller_dashboard/presentation/pages/orders/seller_order_list_screen.dart';
import '../../features/seller_dashboard/presentation/pages/seller_profile_screen.dart';
import '../../features/seller_dashboard/presentation/pages/seller_main_layout.dart';
import '../../features/seller_dashboard/presentation/pages/deliverers/seller_deliverer_list_screen.dart';
import '../../features/live/presentation/pages/live_shopping_screen.dart';
import '../../features/live/presentation/pages/live_viewer_screen.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/root_role_redirect_screen.dart';
import '../../features/products/presentation/pages/client_home_screen.dart';
import '../../features/products/presentation/pages/client_main_layout.dart';
import '../../features/orders/presentation/pages/client_reservations_page.dart';
import '../../features/delivery/presentation/pages/qr_scanner_page.dart';
import '../../features/delivery/presentation/pages/delivery_history_page.dart';
import '../../features/delivery/presentation/pages/delivery_main_layout.dart';
import '../../features/delivery/presentation/pages/delivery_profile_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isGoingToLogin) return '/login';
      if (isLoggedIn && isGoingToLogin) return '/';
      return null;
    },
    routes: [
      // Login route
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      // Delivery agent routes
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DeliveryMainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/delivery/scanner',
                builder: (context, state) => const QrScannerPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/delivery/history',
                builder: (context, state) => const DeliveryHistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/delivery/profile',
                builder: (context, state) => const DeliveryProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // Root router that determines where to go based on role
      GoRoute(
        path: '/',
        builder: (context, state) => const RootRoleRedirectScreen(),
      ),

      // Client route
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ClientMainLayout(navigationShell: navigationShell);
        },
        branches: [
          // Index 0: Accueil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client',
                builder: (context, state) => const ClientHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'live/:liveId',
                    builder: (context, state) => LiveViewerScreen(
                      liveId: state.pathParameters['liveId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Index 1: Commandes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/orders',
                builder: (context, state) => ClientReservationsPage(
                  clientId: Supabase.instance.client.auth.currentUser?.id ?? '',
                ),
                routes: [
                  GoRoute(
                    path: 'details',
                    builder: (context, state) {
                      final reservation = state.extra as Reservation;
                      return ReservationDetailsPage(reservation: reservation);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Index 2: Profil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/profile',
                builder: (context, state) => SellerProfileScreen(
                  sellerId: Supabase.instance.client.auth.currentUser?.id ?? '',
                ),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/profile',
        builder: (context, state) => SellerProfileScreen(
          sellerId: Supabase.instance.client.auth.currentUser?.id ?? '',
        ),
      ),

      // Main shell layout route for Seller
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return SellerMainLayout(navigationShell: navigationShell);
        },
        branches: [
          // Index 0: Accueil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/dashboard',
                builder: (context, state) => const SellerDashboardScreen(),
              ),
            ],
          ),
          // Index 1: Produits
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/products',
                builder: (context, state) => SellerProductListScreen(
                  sellerId: Supabase.instance.client.auth.currentUser?.id ?? '',
                ),
              ),
            ],
          ),
          // Index 2: Go Live (Live Shopping)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/live_shopping',
                builder: (context, state) => const LiveShoppingScreen(),
              ),
            ],
          ),
          // Index 3: Commandes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/orders',
                builder: (context, state) => SellerOrderListScreen(
                  sellerId: Supabase.instance.client.auth.currentUser?.id ?? '',
                ),
              ),
            ],
          ),
          // Index 4: Mes Livreurs
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/deliverers',
                builder: (context, state) => SellerDelivererListScreen(
                  sellerId: Supabase.instance.client.auth.currentUser?.id ?? '',
                ),
              ),
            ],
          ),
          // Index 5: Profil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/profile',
                builder: (context, state) => SellerProfileScreen(
                  sellerId: Supabase.instance.client.auth.currentUser?.id ?? '',
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
