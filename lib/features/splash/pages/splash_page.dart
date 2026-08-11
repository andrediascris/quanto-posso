import 'package:flutter/material.dart';
import 'package:quanto_posso/shared/widgets/app_logo.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const SafeArea(child: Center(child: AppLogo(width: 220))),
    );
  }
}
