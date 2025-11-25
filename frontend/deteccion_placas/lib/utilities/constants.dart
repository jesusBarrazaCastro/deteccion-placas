import 'package:flutter/material.dart';

class Constants {

  static Color getColorForRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.indigo;
      case 'supervisor':
        return Colors.teal;
      case 'tecnico':
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }

  static IconData getIconForRole(String status) {
    switch (status.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'supervisor':
        return Icons.manage_accounts;
      case 'tecnico':
        return Icons.build_circle;
      default:
        return Icons.help;
    }
  }


}
