import 'package:flutter/material.dart';
import '../services/web_auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_alert_banner.dart';

class WebLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const WebLoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  final WebAuthService _authService = WebAuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProfile = await _authService.signInWithGoogle();
      if (userProfile == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Role Gate Check: Only staff and admin allowed
      if (!userProfile.isStaffOrAdmin) {
        await _authService.signOut();
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Từ chối truy cập: Tài khoản "${userProfile.email}" thuộc vai trò Sinh viên (user).\n'
              'Cổng Web Admin chỉ dành riêng cho Cố vấn học tập (staff) và Quản trị viên (admin).';
        });
        return;
      }

      widget.onLoginSuccess();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Đăng nhập thất bại: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderStructural, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EduPlan',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlueSurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADMIN & STAFF PORTAL',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                const Text(
                  'Cổng Cố Vấn & Quản Trị Đào Tạo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Đăng nhập bằng tài khoản Google trường FPT để phê duyệt kế hoạch học tập và quản lý môn học.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Error Banner if role check fails
                if (_errorMessage != null) ...[
                  AppAlertBanner(message: _errorMessage!, isError: true),
                  const SizedBox(height: 20),
                ],

                // Google Sign In Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    side: const BorderSide(color: AppColors.borderStructural, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                              height: 20,
                              width: 20,
                              errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Đăng nhập bằng Google',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 24),
                const Divider(height: 1, color: AppColors.borderStructural),
                const SizedBox(height: 16),

                // Footer note
                const Text(
                  'Hệ thống kiểm tra vai trò tự động (RBAC Security Rules).\nTài khoản sinh viên thông thường sẽ bị từ chối đăng nhập.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
