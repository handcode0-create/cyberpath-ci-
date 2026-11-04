import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'state/providers.dart';

class CyberPathApp extends StatelessWidget {
  const CyberPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CyberPath CI',
      debugShowCheckedModeBanner: false,
      theme: buildCyberPathTheme(),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _RootGate(),
    );
  }
}

class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarded = ref.watch(profileProvider.select((p) => p.onboarded));
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: onboarded ? const HomeShell() : const OnboardingScreen(),
    );
  }
}
