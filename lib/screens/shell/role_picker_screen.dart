import 'package:flutter/material.dart';
import 'package:gendut_garage/models/app_role.dart';
import 'package:gendut_garage/screens/shell/role_shell_screen.dart';
import 'package:gendut_garage/state/app_state.dart';
import 'package:gendut_garage/widgets/gg_logo.dart';
import 'package:provider/provider.dart';

class RolePickerScreen extends StatelessWidget {
  const RolePickerScreen({super.key});

  static const routeName = '/role-picker';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masuk ke Mode'),
        actions: [
          IconButton(
            onPressed: () => context.read<AppState>().signOut(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const GGLogoMark(size: 44, showGlow: false),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pilih tampilan role untuk preview frontend.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  children: const [
                    _RoleCard(role: AppRole.pelanggan),
                    SizedBox(height: 12),
                    _RoleCard(role: AppRole.kasir),
                    SizedBox(height: 12),
                    _RoleCard(role: AppRole.montir),
                    SizedBox(height: 12),
                    _RoleCard(role: AppRole.owner),
                    SizedBox(height: 12),
                    _RoleCard(role: AppRole.admin),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final meta = role.meta;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => RoleShellScreen(role: role)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.14),
                ),
                child: Icon(
                  meta.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
