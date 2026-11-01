import 'dart:ui';
import 'package:flutter/material.dart';
import '../main.dart';

enum SweetAlertType { success, error, warning, info }

class SweetAlert {
  static void showToast(
    String message, {
    SweetAlertType type = SweetAlertType.success,
    String? title,
    bool autoDismiss = true,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    String defaultTitle;
    IconData iconData;
    Color iconColor;
    Color borderColor;

    switch (type) {
      case SweetAlertType.success:
        defaultTitle = 'Success';
        iconData = Icons.check_circle_rounded;
        iconColor = const Color(0xFF34D399);
        borderColor = const Color(0xFF34D399);
        break;
      case SweetAlertType.error:
        defaultTitle = 'Error';
        iconData = Icons.error_rounded;
        iconColor = const Color(0xFFFCA5A5);
        borderColor = const Color(0xFFEF4444);
        break;
      case SweetAlertType.warning:
        defaultTitle = 'Warning';
        iconData = Icons.warning_rounded;
        iconColor = const Color(0xFFFCD34D);
        borderColor = const Color(0xFFF59E0B);
        break;
      case SweetAlertType.info:
        defaultTitle = 'Information';
        iconData = Icons.info_rounded;
        iconColor = const Color(0xFF38BDF8);
        borderColor = const Color(0xFF0284C7);
        break;
    }

    final alertTitle = title ?? defaultTitle;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        if (autoDismiss) {
          Future.delayed(const Duration(milliseconds: 3000), () {
            if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop();
            }
          });
        }

        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF0D3B66).withValues(alpha: 0.95),
                            const Color(0xFF05192D).withValues(alpha: 0.98),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: borderColor.withValues(alpha: 0.25),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                          const BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Glowing Icon
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(color: iconColor.withValues(alpha: 0.6), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: iconColor.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Icon(iconData, color: iconColor, size: 24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Text Content
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alertTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFFBAE6FD),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Action Button
                          if (!autoDismiss)
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: iconColor.withValues(alpha: 0.15),
                                foregroundColor: iconColor,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: iconColor.withValues(alpha: 0.3)),
                                ),
                              ),
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: const Text(
                                'OK',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              splashRadius: 20,
                              tooltip: 'Dismiss',
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ).drive(Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  static Future<void> showSuccess(BuildContext context, String message, {String? title, VoidCallback? onConfirm, bool autoDismiss = true}) async {
    showToast(message, type: SweetAlertType.success, title: title, autoDismiss: autoDismiss);
    if (onConfirm != null) onConfirm();
  }

  static Future<void> showError(BuildContext context, String message, {String? title, VoidCallback? onConfirm, bool autoDismiss = false}) async {
    showToast(message, type: SweetAlertType.error, title: title, autoDismiss: autoDismiss);
    if (onConfirm != null) onConfirm();
  }

  static Future<void> showWarning(BuildContext context, String message, {String? title, VoidCallback? onConfirm, bool autoDismiss = false}) async {
    showToast(message, type: SweetAlertType.warning, title: title, autoDismiss: autoDismiss);
    if (onConfirm != null) onConfirm();
  }

  static Future<void> showInfo(BuildContext context, String message, {String? title, VoidCallback? onConfirm, bool autoDismiss = true}) async {
    showToast(message, type: SweetAlertType.info, title: title, autoDismiss: autoDismiss);
    if (onConfirm != null) onConfirm();
  }

  static Future<void> showGlobalSuccess(String message, {String? title}) async {
    showToast(message, type: SweetAlertType.success, title: title, autoDismiss: true);
  }

  static Future<void> showGlobalError(String message, {String? title}) async {
    showToast(message, type: SweetAlertType.error, title: title, autoDismiss: false);
  }

  static Future<void> showGlobalWarning(String message, {String? title}) async {
    showToast(message, type: SweetAlertType.warning, title: title, autoDismiss: false);
  }

  static Future<void> showGlobalInfo(String message, {String? title}) async {
    showToast(message, type: SweetAlertType.info, title: title, autoDismiss: true);
  }
}
