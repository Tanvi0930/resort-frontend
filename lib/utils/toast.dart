import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class AppToast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final config = _config(type);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          duration: duration,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: config.bg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Icon(config.icon, color: config.iconColor, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(message, style: TextStyle(color: config.textColor, fontSize: 13, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
        ),
      );
  }

  static _ToastConfig _config(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastConfig(bg: const Color(0xFFF0FDF4), icon: Icons.check_circle_outline, iconColor: const Color(0xFF2E7D52), textColor: const Color(0xFF14532D));
      case ToastType.error:
        return _ToastConfig(bg: const Color(0xFFFEF2F2), icon: Icons.error_outline, iconColor: Colors.red.shade600, textColor: Colors.red.shade800);
      case ToastType.warning:
        return _ToastConfig(bg: const Color(0xFFFFFBEB), icon: Icons.warning_amber_rounded, iconColor: Colors.orange.shade600, textColor: Colors.orange.shade900);
      case ToastType.info:
        return _ToastConfig(bg: const Color(0xFFEFF6FF), icon: Icons.info_outline, iconColor: Colors.blue.shade600, textColor: Colors.blue.shade900);
    }
  }
}

class _ToastConfig {
  final Color bg, iconColor, textColor;
  final IconData icon;
  const _ToastConfig({required this.bg, required this.icon, required this.iconColor, required this.textColor});
}
