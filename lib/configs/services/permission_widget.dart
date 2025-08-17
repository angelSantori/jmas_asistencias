import 'package:flutter/material.dart';
import 'package:jmas_asistencias/configs/services/auth_service.dart';

class PermissionWidget extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? unauthorizedChild;
  final Widget? loadingWidget;
  
  const PermissionWidget({
    super.key,
    required this.permission,
    required this.child,
    this.unauthorizedChild,
    this.loadingWidget,
  });
  
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return FutureBuilder<bool>(
      future: authService.hasPermission(permission),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.data == true) {
          return child;
        }
        
        return unauthorizedChild ?? const SizedBox.shrink();
      },
    );
  }
}