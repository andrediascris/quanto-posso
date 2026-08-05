import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  // =====================================
  // CARD SHADOW
  // =====================================

  /// Sombra padrão para cards financeiros
  static const BoxShadow card = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 20,
    offset: Offset(0, 8),
  );

  // =====================================
  // ELEVATED COMPONENTS
  // =====================================

  /// Elementos com maior destaque
  /// Ex: saldo principal da Home
  static const BoxShadow elevated = BoxShadow(
    color: Color(0x22000000),
    blurRadius: 24,
    offset: Offset(0, 12),
  );

  // =====================================
  // BUTTON / FAB
  // =====================================

  /// Botões principais e Floating Action Button
  static const BoxShadow button = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 16,
    offset: Offset(0, 6),
  );

  // =====================================
  // NONE
  // =====================================

  static const List<BoxShadow> none = [];
}
