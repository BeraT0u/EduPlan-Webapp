import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'screens/announcements_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/reviews_screen.dart';
import 'services/web_auth_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/web_shell_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.web,
  );
  runApp(const EduPlanWebAdminApp());
}

class EduPlanWebAdminApp extends StatelessWidget {
  const EduPlanWebAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduPlan - Cổng Quản Trị & Cố Vấn Học Vụ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.warmPaperTheme,
      home: const WebRootGate(),
    );
  }
}

class WebRootGate extends StatefulWidget {
  const WebRootGate({super.key});

  @override
  State<WebRootGate> createState() => _WebRootGateState();
}

class _WebRootGateState extends State<WebRootGate> {
  final WebAuthService _authService = WebAuthService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundCanvas,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
          );
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return WebLoginScreen(onLoginSuccess: () => setState(() {}));
        }

        // Fetch User profile from Firestore to enforce Role Gate
        return FutureBuilder<UserModel?>(
          future: _authService.getCurrentUserProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppColors.backgroundCanvas,
                body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
              );
            }

            final userProfile = profileSnapshot.data;
            if (userProfile == null || !userProfile.isStaffOrAdmin) {
              // Sign out immediately if not staff/admin
              _authService.signOut();
              return WebLoginScreen(onLoginSuccess: () => setState(() {}));
            }

            // Screen switcher
            Widget activeScreen;
            String screenTitle;

            switch (_selectedIndex) {
              case 0:
                activeScreen = DashboardScreen(
                  onNavigateToReviews: () => setState(() => _selectedIndex = 2),
                );
                screenTitle = 'Dashboard Học Vụ & Thống Kê Tổng Hợp';
                break;
              case 1:
                activeScreen = CoursesScreen(currentUser: userProfile);
                screenTitle = 'Quản Trị Danh Mục Môn Học (Course Catalog)';
                break;
              case 2:
                activeScreen = ReviewsScreen(currentUser: userProfile);
                screenTitle = 'Hàng Đợi Duyệt Kế Hoạch Học Tập (Review Queue)';
                break;
              case 3:
                activeScreen = AnnouncementsScreen(currentUser: userProfile);
                screenTitle = 'Phát Hành Thông Báo & Phân Quyền Tài Khoản';
                break;
              default:
                activeScreen = const SizedBox();
                screenTitle = 'EduPlan Admin';
            }

            return WebShellScaffold(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              currentUser: userProfile,
              title: screenTitle,
              body: activeScreen,
            );
          },
        );
      },
    );
  }
}
