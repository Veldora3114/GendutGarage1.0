import 'package:flutter/material.dart';
import 'package:gendut_garage/screens/auth/forgot_password_screen.dart';
import 'package:gendut_garage/screens/auth/signup_screen.dart';
import 'package:gendut_garage/screens/shell/auth_gate.dart';
import 'package:gendut_garage/state/app_state.dart';
import 'package:gendut_garage/theme/gg_theme.dart';
import 'package:provider/provider.dart';

class GendutGarageApp extends StatelessWidget {
  const GendutGarageApp({super.key, this.enableSupabase = true});

  final bool enableSupabase;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final state = AppState(enableSupabase: enableSupabase);
        state.init();
        return state;
      },
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: 'Gendut Garage',
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            theme: GGTheme.light(),
            darkTheme: GGTheme.dark(),
            home: const AuthGate(),
            routes: {
              SignupScreen.routeName: (_) => const SignupScreen(),
              ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(),
            },
          );
        },
      ),
    );
  }
}
