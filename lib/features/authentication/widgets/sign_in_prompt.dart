import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/authentication_cubit.dart';

class SignInPrompt extends StatelessWidget {
  final String title;
  final String description;

  const SignInPrompt({
    super.key,
    this.title = 'Увійдіть, щоб продовжити',
    this.description = 'Для доступу до цього функціоналу необхідно увійти через Google акаунт',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E293B),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 40,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 32),
            BlocBuilder<AuthenticationCubit, AuthenticationState>(
              builder: (context, state) {
                final isLoading = state.status == AuthenticationStatus.loading;
                return ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => context.read<AuthenticationCubit>().signIn(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.g_mobiledata, size: 24),
                  label: Text(
                    isLoading ? 'Вхід...' : 'Увійти через Google',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

void showSignInDialog(BuildContext context, {String? message}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.1),
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 30,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Необхідна авторизація',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message ?? 'Для виконання планування необхідно увійти через Google акаунт',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            BlocConsumer<AuthenticationCubit, AuthenticationState>(
              listener: (context, state) {
                if (state.status == AuthenticationStatus.authenticated) {
                  Navigator.of(context).pop();
                }
              },
              builder: (context, state) {
                final isLoading = state.status == AuthenticationStatus.loading;
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => context.read<AuthenticationCubit>().signIn(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.g_mobiledata, size: 24),
                        label: Text(
                          isLoading ? 'Вхід...' : 'Увійти через Google',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Скасувати',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

