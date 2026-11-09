import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduplan_web_admin/models/user_model.dart';
import 'package:eduplan_web_admin/screens/login_screen.dart';
import 'package:eduplan_web_admin/theme/app_theme.dart';
import 'package:eduplan_web_admin/widgets/app_alert_banner.dart';
import 'package:eduplan_web_admin/widgets/kpi_card.dart';
import 'package:eduplan_web_admin/widgets/web_shell_scaffold.dart';

void main() {
  group('Web Admin UI & Navigation Widget Tests', () {
    testWidgets('WebLoginScreen renders properly and handles demo staff/admin login buttons',
        (tester) async {
      UserModel? loggedInUser;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.warmPaperTheme,
          home: WebLoginScreen(
            onLoginSuccess: () {},
            onDemoLogin: (user) => loggedInUser = user,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & branding
      expect(find.text('Cổng Cố Vấn & Quản Trị Đào Tạo'), findsOneWidget);
      expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
      expect(find.text('Staff Demo'), findsOneWidget);
      expect(find.text('Admin Demo'), findsOneWidget);

      // Tap Staff Demo
      await tester.tap(find.text('Staff Demo'));
      await tester.pumpAndSettle();

      expect(loggedInUser, isNotNull);
      expect(loggedInUser!.role, 'staff');
      expect(loggedInUser!.email, 'staff@fpt.edu.vn');

      // Tap Admin Demo
      await tester.tap(find.text('Admin Demo'));
      await tester.pumpAndSettle();

      expect(loggedInUser, isNotNull);
      expect(loggedInUser!.role, 'admin');
      expect(loggedInUser!.email, 'admin@fpt.edu.vn');
    });

    testWidgets('WebShellScaffold renders sidebar, navigation tabs, and handles tab switching',
        (tester) async {
      int selectedTab = 0;
      bool signedOut = false;

      final testUser = UserModel(
        uid: 'staff_123',
        email: 'advisor@fe.edu.vn',
        displayName: 'Cố vấn Mai Phương',
        role: 'staff',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.warmPaperTheme,
          home: StatefulBuilder(
            builder: (context, setState) {
              return WebShellScaffold(
                selectedIndex: selectedTab,
                onDestinationSelected: (idx) {
                  setState(() => selectedTab = idx);
                },
                currentUser: testUser,
                title: 'Trang kiểm thử',
                body: Text('Nội dung tab $selectedTab'),
                onSignOut: () => signedOut = true,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header branding and staff portal pill
      expect(find.text('EduPlan'), findsOneWidget);
      expect(find.text('STAFF PORTAL'), findsOneWidget);
      expect(find.text('Cố vấn Mai Phương'), findsOneWidget);
      expect(find.text('advisor@fe.edu.vn'), findsOneWidget);

      // Verify 4 tabs
      expect(find.text('Dashboard Thống kê'), findsOneWidget);
      expect(find.text('Quản trị Môn học'), findsOneWidget);
      expect(find.text('Hàng đợi Duyệt'), findsOneWidget);
      expect(find.text('Thông báo & Phân quyền'), findsOneWidget);

      // Initial tab content
      expect(find.text('Nội dung tab 0'), findsOneWidget);

      // Tap 'Quản trị Môn học' (Tab 1)
      await tester.tap(find.text('Quản trị Môn học'));
      await tester.pumpAndSettle();
      expect(selectedTab, 1);
      expect(find.text('Nội dung tab 1'), findsOneWidget);

      // Tap 'Hàng đợi Duyệt' (Tab 2)
      await tester.tap(find.text('Hàng đợi Duyệt'));
      await tester.pumpAndSettle();
      expect(selectedTab, 2);
      expect(find.text('Nội dung tab 2'), findsOneWidget);

      // Tap 'Thông báo & Phân quyền' (Tab 3)
      await tester.tap(find.text('Thông báo & Phân quyền'));
      await tester.pumpAndSettle();
      expect(selectedTab, 3);
      expect(find.text('Nội dung tab 3'), findsOneWidget);

      // Tap logout button
      await tester.tap(find.byTooltip('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(signedOut, isTrue);
    });

    testWidgets('KpiCard renders metric data and badges properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.warmPaperTheme,
          home: Scaffold(
            body: KpiCard(
              title: 'Kế hoạch chờ duyệt',
              value: '14',
              subtitle: 'Cần xử lý trong tuần này',
              icon: Icons.pending_actions,
              iconColor: Colors.orange,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kế hoạch chờ duyệt'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('Cần xử lý trong tuần này'), findsOneWidget);
      expect(find.byIcon(Icons.pending_actions), findsOneWidget);
    });

    testWidgets('AppAlertBanner renders error and info messages with correct styling',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppAlertBanner(
                  message: 'Thông báo cảnh báo lỗi nghiêm trọng',
                  isError: true,
                ),
                AppAlertBanner(
                  message: 'Cập nhật thành công kế hoạch học tập',
                  isError: false,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thông báo cảnh báo lỗi nghiêm trọng'), findsOneWidget);
      expect(find.text('Cập nhật thành công kế hoạch học tập'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });
}
