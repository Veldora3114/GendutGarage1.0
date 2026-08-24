import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gendut_garage/config/gg_supabase.dart';
import 'package:gendut_garage/models/app_role.dart';
import 'package:gendut_garage/models/attendance.dart';
import 'package:gendut_garage/models/booking.dart';
import 'package:gendut_garage/models/invoice.dart';
import 'package:gendut_garage/models/job.dart';
import 'package:gendut_garage/models/part.dart';
import 'package:gendut_garage/models/profile.dart';
import 'package:gendut_garage/services/invoice_pdf.dart';
import 'package:gendut_garage/services/mod_calculator.dart';
import 'package:gendut_garage/services/reward_engine.dart';
import 'package:gendut_garage/state/app_state.dart';
import 'package:gendut_garage/widgets/gg_logo.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class RoleShellScreen extends StatefulWidget {
  const RoleShellScreen({super.key, required this.role});

  final AppRole role;

  @override
  State<RoleShellScreen> createState() => _RoleShellScreenState();
}

class _RoleShellScreenState extends State<RoleShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final config = _navConfigForRole(widget.role);
    final tabs = config.tabs;
    final destinations = tabs
        .map(
          (t) => NavigationDestination(
            icon: Icon(t.icon),
            selectedIcon: Icon(t.selectedIcon ?? t.icon),
            label: t.label,
          ),
        )
        .toList();

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index.clamp(0, tabs.length - 1),
          children: [
            for (final t in tabs)
              _ScaffoldTab(
                role: widget.role,
                title: t.label,
                child: t.builder(context),
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index.clamp(0, tabs.length - 1),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.label,
    required this.icon,
    this.selectedIcon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final WidgetBuilder builder;
}

class _NavConfig {
  const _NavConfig(this.tabs);
  final List<_NavTab> tabs;
}

_NavConfig _navConfigForRole(AppRole role) {
  switch (role) {
    case AppRole.pelanggan:
      return _NavConfig([
        _NavTab(
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          builder: (_) => const _CustomerHome(),
        ),
        _NavTab(
          label: 'Status',
          icon: Icons.track_changes_outlined,
          selectedIcon: Icons.track_changes_rounded,
          builder: (_) => const _CustomerStatus(),
        ),
        _NavTab(
          label: 'Booking',
          icon: Icons.event_available_outlined,
          selectedIcon: Icons.event_available_rounded,
          builder: (_) => const _CustomerBooking(),
        ),
        _NavTab(
          label: 'Invoice',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          builder: (_) => const _CustomerInvoices(),
        ),
        _NavTab(
          label: 'Profil',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          builder: (_) => const _CustomerProfile(),
        ),
      ]);
    case AppRole.admin:
      return _NavConfig([
        _NavTab(
          label: 'Booking',
          icon: Icons.event_note_outlined,
          selectedIcon: Icons.event_note_rounded,
          builder: (_) => const _AdminBooking(),
        ),
        _NavTab(
          label: 'Job',
          icon: Icons.build_circle_outlined,
          selectedIcon: Icons.build_circle_rounded,
          builder: (_) => const _AdminJobs(),
        ),
        _NavTab(
          label: 'Invoice',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          builder: (_) => const _AdminInvoices(),
        ),
        _NavTab(
          label: 'Stok',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2_rounded,
          builder: (_) => const _AdminStock(),
        ),
        _NavTab(
          label: 'Staff',
          icon: Icons.manage_accounts_outlined,
          selectedIcon: Icons.manage_accounts_rounded,
          builder: (_) => const _AdminStaff(),
        ),
      ]);
    case AppRole.kasir:
      return _NavConfig([
        _NavTab(
          label: 'Job',
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment_rounded,
          builder: (_) => const _CashierJobs(),
        ),
        _NavTab(
          label: 'Invoice',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          builder: (_) => const _CashierInvoices(),
        ),
        _NavTab(
          label: 'Bayar',
          icon: Icons.payments_outlined,
          selectedIcon: Icons.payments_rounded,
          builder: (_) => const _CashierPayments(),
        ),
        _NavTab(
          label: 'Riwayat',
          icon: Icons.history_outlined,
          selectedIcon: Icons.history_rounded,
          builder: (_) => const _CashierHistory(),
        ),
      ]);
    case AppRole.montir:
      return _NavConfig([
        _NavTab(
          label: 'Job',
          icon: Icons.format_list_bulleted_outlined,
          selectedIcon: Icons.format_list_bulleted_rounded,
          builder: (_) => const _MechanicJobs(),
        ),
        _NavTab(
          label: 'Detail',
          icon: Icons.description_outlined,
          selectedIcon: Icons.description_rounded,
          builder: (_) => const _MechanicJobDetail(),
        ),
        _NavTab(
          label: 'Part',
          icon: Icons.construction_outlined,
          selectedIcon: Icons.construction_rounded,
          builder: (_) => const _MechanicParts(),
        ),
      ]);
    case AppRole.owner:
      return _NavConfig([
        _NavTab(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
          builder: (_) => const _OwnerDashboard(),
        ),
        _NavTab(
          label: 'Laporan',
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart_rounded,
          builder: (_) => const _OwnerReports(),
        ),
        _NavTab(
          label: 'Stok',
          icon: Icons.inventory_outlined,
          selectedIcon: Icons.inventory_rounded,
          builder: (_) => const _OwnerStockCritical(),
        ),
        _NavTab(
          label: 'Profil',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          builder: (_) => const _OwnerProfile(),
        ),
      ]);
  }
}

class _ScaffoldTab extends StatelessWidget {
  const _ScaffoldTab({
    required this.role,
    required this.title,
    required this.child,
  });

  final AppRole role;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Theme.of(
            context,
          ).scaffoldBackgroundColor.withValues(alpha: 0.96),
          title: Row(
            children: [
              const GGLogoMark(size: 40, showGlow: false),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                    role.meta.title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () async {
                await _showThemePicker(context);
              },
              icon: const Icon(Icons.brightness_6_rounded),
              tooltip: 'Tema',
            ),
            IconButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Memperbarui data...')),
                );
                try {
                  await context.read<AppState>().manualRefresh();
                  if (!context.mounted) return;
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Data sudah diperbarui')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    SnackBar(content: Text(_friendlyError(e))),
                  );
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
            IconButton(
              onPressed: () {
                context.read<AppState>().signOut();
              },
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Logout',
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _normalizeWhatsapp(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  if (digits.startsWith('62')) return digits;
  if (digits.startsWith('0')) return '62${digits.substring(1)}';
  if (digits.startsWith('8')) return '62$digits';
  return digits;
}

String _displayWhatsapp(String? normalized) {
  final n = (normalized ?? '').trim();
  if (n.isEmpty) return 'Belum diisi';
  return n.startsWith('62') ? '+$n' : n;
}

Future<void> _openWhatsappChat({
  required BuildContext context,
  required String normalizedNumber,
  required String message,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final num = _normalizeWhatsapp(normalizedNumber);
  if (num.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Nomor WhatsApp tidak valid')),
    );
    return;
  }
  final uri = Uri.parse(
    'https://wa.me/$num?text=${Uri.encodeComponent(message)}',
  );
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Tidak bisa membuka WhatsApp')),
    );
  }
}

String _themeModeLabel(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => 'Terang',
    ThemeMode.dark => 'Gelap',
    ThemeMode.system => 'System',
  };
}

Future<void> _showThemePicker(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) {
      final state = context.watch<AppState>();
      final scheme = Theme.of(context).colorScheme;
      final current = state.themeMode;

      Widget row({
        required ThemeMode mode,
        required String title,
        required String subtitle,
      }) {
        final selected = current == mode;
        return ListTile(
          leading: Icon(
            mode == ThemeMode.light
                ? Icons.light_mode_rounded
                : (mode == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : Icons.settings_rounded),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(subtitle),
          trailing: selected
              ? Icon(Icons.check_rounded, color: scheme.primary)
              : const SizedBox.shrink(),
          onTap: () async {
            await context.read<AppState>().setThemeMode(mode);
            if (context.mounted) Navigator.of(context).pop();
          },
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pilih Tema',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  row(
                    mode: ThemeMode.system,
                    title: 'System',
                    subtitle: 'Mengikuti setting HP',
                  ),
                  Divider(
                    height: 1,
                    indent: 14,
                    endIndent: 14,
                    color: scheme.onSurface.withValues(alpha: 0.10),
                  ),
                  row(
                    mode: ThemeMode.light,
                    title: 'Terang',
                    subtitle: 'Mode terang',
                  ),
                  Divider(
                    height: 1,
                    indent: 14,
                    endIndent: 14,
                    color: scheme.onSurface.withValues(alpha: 0.10),
                  ),
                  row(
                    mode: ThemeMode.dark,
                    title: 'Gelap',
                    subtitle: 'Mode gelap',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showWhatsappEditor(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      final state = context.watch<AppState>();
      final controller = TextEditingController(
        text: state.whatsappNumber ?? '',
      );

      return Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nomor WhatsApp',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              'Contoh: 08xxxxxxxxxx atau +62xxxxxxxxxx',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.70),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () async {
                final n = controller.text.trim();
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await context.read<AppState>().setWhatsappNumber(n);
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(_friendlyError(e))),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
    },
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withValues(alpha: 0.70),
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: c.withValues(alpha: 0.14),
              ),
              child: Icon(icon, color: c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceSelfCard extends StatefulWidget {
  const _AttendanceSelfCard();

  @override
  State<_AttendanceSelfCard> createState() => _AttendanceSelfCardState();
}

class _AttendanceSelfCardState extends State<_AttendanceSelfCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();
    if (profile.role != AppRole.admin &&
        profile.role != AppRole.kasir &&
        profile.role != AppRole.montir) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final rec = state.findMyTodayAttendance();
    final AttendanceState s = rec == null
        ? AttendanceState.notCheckedIn
        : rec.state;

    String statusLabel() {
      return switch (s) {
        AttendanceState.notCheckedIn => 'Belum Masuk',
        AttendanceState.working => 'Sedang Kerja',
        AttendanceState.breakTime => 'Istirahat',
        AttendanceState.checkedOut => 'Sudah Pulang',
      };
    }

    Color statusColor() {
      return switch (s) {
        AttendanceState.notCheckedIn => scheme.tertiary,
        AttendanceState.working => Colors.green,
        AttendanceState.breakTime => scheme.primary,
        AttendanceState.checkedOut => scheme.onSurface.withValues(alpha: 0.55),
      };
    }

    String fmtLate(Duration d) {
      final minutes = d.inMinutes;
      final h = minutes ~/ 60;
      final m = minutes % 60;
      if (h <= 0) return '$m menit';
      if (m == 0) return '$h jam';
      return '$h jam $m menit';
    }

    String? lateInfo() {
      if (rec == null || rec!.checkInMs <= 0) return null;
      final inAt = DateTime.fromMillisecondsSinceEpoch(rec!.checkInMs);
      final scheduledIn = DateTime(inAt.year, inAt.month, inAt.day, 8, 0);
      String? inLate;
      if (inAt.isAfter(scheduledIn)) {
        inLate = 'Terlambat datang ${fmtLate(inAt.difference(scheduledIn))}';
      }

      String? outLate;
      final outMs = rec!.checkOutMs;
      if (outMs != null) {
        final outAt = DateTime.fromMillisecondsSinceEpoch(outMs);
        final scheduledOut = DateTime(
          outAt.year,
          outAt.month,
          outAt.day,
          16,
          0,
        );
        if (outAt.isAfter(scheduledOut)) {
          outLate =
              'Terlambat pulang ${fmtLate(outAt.difference(scheduledOut))}';
        }
      }

      if (inLate != null && outLate != null) return '$inLate • $outLate';
      return inLate ?? outLate;
    }

    Future<void> runVoid(Future<void> Function(AppState) op) async {
      if (_loading) return;
      setState(() => _loading = true);
      final messenger = ScaffoldMessenger.of(context);
      try {
        await op(context.read<AppState>());
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(_friendlyError(e))));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }

    Future<void> checkIn() async {
      if (_loading) return;
      setState(() => _loading = true);
      final messenger = ScaffoldMessenger.of(context);
      try {
        await context.read<AppState>().attendanceCheckIn();
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(_friendlyError(e))));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }

    Future<void> checkOut() async {
      if (_loading) return;
      setState(() => _loading = true);
      final messenger = ScaffoldMessenger.of(context);
      try {
        await context.read<AppState>().attendanceCheckOut();
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(_friendlyError(e))));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }

    final subtitleParts = <String>[];
    if (rec != null && rec.checkInMs > 0) {
      subtitleParts.add('Masuk ${_fmtHHmm(rec.checkInMs)}');
    }
    if (rec != null && rec.breakStartMs != null && rec.breakEndMs == null) {
      subtitleParts.add('Mulai istirahat ${_fmtHHmm(rec.breakStartMs!)}');
    }
    if (rec != null && rec.breakStartMs != null && rec.breakEndMs != null) {
      subtitleParts.add('Istirahat selesai ${_fmtHHmm(rec.breakEndMs!)}');
    }
    if (rec != null && rec.checkOutMs != null) {
      subtitleParts.add('Pulang ${_fmtHHmm(rec.checkOutMs!)}');
    }
    final late = lateInfo();
    if (late != null) {
      subtitleParts.add(late);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              title: 'Absensi Hari Ini',
              trailing: _StatusChip(label: statusLabel(), color: statusColor()),
            ),
            if (subtitleParts.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                subtitleParts.join(' • '),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (s == AttendanceState.notCheckedIn)
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: _loading ? null : checkIn,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Masuk'),
                ),
              )
            else if (s == AttendanceState.working)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _loading
                            ? null
                            : () => runVoid(
                                (a) async => a.attendanceBreakStart(),
                              ),
                        icon: const Icon(Icons.free_breakfast_rounded),
                        label: const Text('Istirahat'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : checkOut,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Pulang'),
                      ),
                    ),
                  ),
                ],
              )
            else if (s == AttendanceState.breakTime)
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: _loading
                      ? null
                      : () => runVoid((a) async => a.attendanceBreakEnd()),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Kembali Kerja'),
                ),
              )
            else
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Selesai'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OwnerAttendancePreview extends StatelessWidget {
  const _OwnerAttendancePreview();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();
    if (profile.role != AppRole.owner) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final staff = state.staff.where(
      (p) =>
          p.role == AppRole.admin ||
          p.role == AppRole.kasir ||
          p.role == AppRole.montir,
    );
    final staffList = staff.toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final byStaff = <String, AttendanceRecord>{};
    for (final a in state.listAttendance()) {
      final d = DateTime(a.workDate.year, a.workDate.month, a.workDate.day);
      if (d != today) continue;
      byStaff[a.staffId] = a;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              title: 'Absensi Hari Ini',
              trailing: TextButton(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const _OwnerAttendanceSheet(),
                  );
                },
                child: const Text('Lihat'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: staffList.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Belum ada staff.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < staffList.length; i++)
                          Column(
                            children: [
                              _AttendanceStaffRow(
                                staff: staffList[i],
                                record: byStaff[staffList[i].userId],
                              ),
                              if (i != staffList.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 14,
                                  endIndent: 14,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.10,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceStaffRow extends StatelessWidget {
  const _AttendanceStaffRow({required this.staff, required this.record});

  final UserProfile staff;
  final AttendanceRecord? record;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = record?.state ?? AttendanceState.notCheckedIn;
    final label = switch (s) {
      AttendanceState.notCheckedIn => 'Belum Masuk',
      AttendanceState.working => 'Kerja',
      AttendanceState.breakTime => 'Istirahat',
      AttendanceState.checkedOut => 'Pulang',
    };
    final color = switch (s) {
      AttendanceState.notCheckedIn => scheme.tertiary,
      AttendanceState.working => Colors.green,
      AttendanceState.breakTime => scheme.primary,
      AttendanceState.checkedOut => scheme.onSurface.withValues(alpha: 0.55),
    };

    final time = record == null
        ? null
        : (record!.checkOutMs != null
              ? '${_fmtHHmm(record!.checkInMs)}–${_fmtHHmm(record!.checkOutMs!)}'
              : _fmtHHmm(record!.checkInMs));

    String fmtLate(Duration d) {
      final minutes = d.inMinutes;
      final h = minutes ~/ 60;
      final m = minutes % 60;
      if (h <= 0) return '$m menit';
      if (m == 0) return '$h jam';
      return '$h jam $m menit';
    }

    String? lateInfo() {
      if (record == null || record!.checkInMs <= 0) return null;
      final inAt = DateTime.fromMillisecondsSinceEpoch(record!.checkInMs);
      final scheduledIn = DateTime(inAt.year, inAt.month, inAt.day, 8, 0);
      String? inLate;
      if (inAt.isAfter(scheduledIn)) {
        inLate = 'Terlambat masuk ${fmtLate(inAt.difference(scheduledIn))}';
      }

      String? outLate;
      final outMs = record!.checkOutMs;
      if (outMs != null) {
        final outAt = DateTime.fromMillisecondsSinceEpoch(outMs);
        final scheduledOut = DateTime(
          outAt.year,
          outAt.month,
          outAt.day,
          16,
          0,
        );
        if (outAt.isAfter(scheduledOut)) {
          outLate =
              'Terlambat pulang ${fmtLate(outAt.difference(scheduledOut))}';
        }
      }

      if (inLate != null && outLate != null) return '$inLate • $outLate';
      return inLate ?? outLate;
    }

    final late = lateInfo();
    return _ListRow(
      title: staff.fullName.isEmpty ? staff.email : staff.fullName,
      subtitle: time == null
          ? staff.role.meta.title
          : [staff.role.meta.title, time, if (late != null) late].join(' • '),
      icon: Icons.badge_rounded,
      trailing: _StatusChip(label: label, color: color),
    );
  }
}

class _OwnerAttendanceSheet extends StatefulWidget {
  const _OwnerAttendanceSheet();

  @override
  State<_OwnerAttendanceSheet> createState() => _OwnerAttendanceSheetState();
}

class _OwnerAttendanceSheetState extends State<_OwnerAttendanceSheet> {
  DateTime _date = DateTime.now();
  bool _loading = false;
  List<AttendanceRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final list = await context.read<AppState>().listAttendanceByDate(_date);
      if (!mounted) return;
      setState(() => _records = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _records = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = context.watch<AppState>();
    final staff = state.staff.where(
      (p) =>
          p.role == AppRole.admin ||
          p.role == AppRole.kasir ||
          p.role == AppRole.montir,
    );
    final staffList = staff.toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    final byStaff = {for (final a in _records) a.staffId: a};

    final dateLabel =
        "${_date.day.toString().padLeft(2, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.year}";

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: 'Absensi ($dateLabel)',
            trailing: TextButton.icon(
              onPressed: _loading
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 60),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked == null) return;
                      setState(() => _date = picked);
                      await _load();
                    },
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Pilih'),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: _loading
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Memuat...',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < staffList.length; i++)
                        Column(
                          children: [
                            _AttendanceStaffRow(
                              staff: staffList[i],
                              record: byStaff[staffList[i].userId],
                            ),
                            if (i != staffList.length - 1)
                              Divider(
                                height: 1,
                                indent: 14,
                                endIndent: 14,
                                color: scheme.onSurface.withValues(alpha: 0.10),
                              ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

String _fmtHHmm(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: scheme.primary.withValues(alpha: 0.14),
                  ),
                  child: Icon(icon, color: scheme.primary),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: scheme.primary.withValues(alpha: 0.14),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null) const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _CustomerHome extends StatelessWidget {
  const _CustomerHome();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final actor = state.profile;
    final name = (actor?.fullName ?? '').trim().isNotEmpty
        ? actor!.fullName.trim()
        : ((actor?.email ?? '').trim().isNotEmpty
              ? actor!.email.trim()
              : 'pelanggan');
    final bookings = state.listBookings();
    final bookingAktif = bookings
        .where(
          (b) =>
              b.status == BookingStatus.pending ||
              b.status == BookingStatus.confirmed,
        )
        .length;
    final jobs = state.listJobs();
    final servisJalan = jobs
        .where(
          (j) => j.status != JobStatus.done && j.status != JobStatus.cancelled,
        )
        .length;
    final invoices = state.listInvoices();
    final invoiceLunas = invoices
        .where((s) => s.computedPaymentStatus() == PaymentStatus.paid)
        .length;
    final invoicePending = invoices.length - invoiceLunas;

    int timeMinutes(String t) {
      final parts = t.split(':');
      if (parts.length != 2) return 0;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return (h * 60) + m;
    }

    final upcoming =
        bookings
            .where(
              (b) =>
                  b.status != BookingStatus.rejected &&
                  b.status != BookingStatus.cancelled &&
                  b.status != BookingStatus.done,
            )
            .toList()
          ..sort((a, b) {
            final d = a.bookingDate.compareTo(b.bookingDate);
            if (d != 0) return d;
            return timeMinutes(
              a.bookingTime,
            ).compareTo(timeMinutes(b.bookingTime));
          });
    final upcomingLimited = upcoming.take(2).toList();
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: 0.90),
                scheme.primary.withValues(alpha: 0.55),
                scheme.primary.withValues(alpha: 0.28),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                  child: Icon(
                    Icons.motorcycle_rounded,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $name',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withValues(alpha: 0.96),
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Booking lebih rapi, pantau servis, dan upgrade mesin dengan kalkulator.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Ringkasan'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Booking aktif',
                value: '$bookingAktif',
                icon: Icons.event_available_rounded,
                color: scheme.primary,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Servis jalan',
                value: '$servisJalan',
                icon: Icons.track_changes_rounded,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Invoice pending',
                value: '$invoicePending',
                icon: Icons.hourglass_top_rounded,
                color: scheme.tertiary,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Invoice lunas',
                value: '$invoiceLunas',
                icon: Icons.verified_rounded,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _SectionHeader(title: 'Aksi Cepat'),
        const SizedBox(height: 10),
        Row(
          children: [
            _ActionTile(
              label: 'Kendaraan Saya',
              icon: Icons.directions_bike_rounded,
              onTap: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const _VehicleUpsertSheet(vehicleId: null),
                );
              },
            ),
            _ActionTile(
              label: 'Kalkulator CC',
              icon: Icons.calculate_rounded,
              onTap: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const _ModCalculatorSheet(),
                );
              },
            ),
          ],
        ),
        Row(
          children: [
            _ActionTile(
              label: 'Upgrade Mesin',
              icon: Icons.speed_rounded,
              onTap: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const _BookingCreateSheet(
                    initialType: BookingType.modif,
                    lockType: true,
                  ),
                );
              },
            ),
            _ActionTile(
              label: 'Booking Servis',
              icon: Icons.add_task_rounded,
              onTap: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const _BookingCreateSheet(
                    initialType: BookingType.service,
                    lockType: true,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SectionHeader(
          title: 'Booking Terdekat',
          trailing: TextButton(
            onPressed: () async {
              await showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const _CustomerBooking(),
              );
            },
            child: Text(
              'Lihat semua',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: upcomingLimited.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum ada booking.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < upcomingLimited.length; i++)
                      Column(
                        children: [
                          _ListRow(
                            title:
                                '${upcomingLimited[i].type.label} • ${upcomingLimited[i].status.label}',
                            subtitle:
                                '${_fmtDate(upcomingLimited[i].bookingDate)}, ${upcomingLimited[i].bookingTime} • ${upcomingLimited[i].complaint}',
                            icon: upcomingLimited[i].type == BookingType.modif
                                ? Icons.speed_rounded
                                : Icons.event_note_rounded,
                            trailing: _StatusChip(
                              label: upcomingLimited[i].status.label,
                              color: _statusColor(
                                context,
                                upcomingLimited[i].status,
                              ),
                            ),
                            onTap: () async {
                              if (upcomingLimited[i].status ==
                                  BookingStatus.pending) {
                                await showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  builder: (_) => _BookingRescheduleSheet(
                                    booking: upcomingLimited[i],
                                  ),
                                );
                                return;
                              }
                              _toast(
                                context,
                                'Booking sudah ${upcomingLimited[i].status.label.toLowerCase()}.',
                              );
                            },
                          ),
                          if (i != upcomingLimited.length - 1)
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _CustomerStatus extends StatelessWidget {
  const _CustomerStatus();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final jobs = state.listJobs();
    final invoices = state.listInvoices();
    final invoiceByJobId = {for (final s in invoices) s.invoice.jobId: s};
    final active = jobs
        .where(
          (j) => j.status != JobStatus.done && j.status != JobStatus.cancelled,
        )
        .toList();
    final history = jobs.where((j) => j.status == JobStatus.done).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Servis Berjalan'),
        const SizedBox(height: 10),
        Card(
          child: active.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum ada servis berjalan.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < active.length; i++)
                      Column(
                        children: [
                          _ListRow(
                            title: active[i].id.toUpperCase(),
                            subtitle: () {
                              final inv = invoiceByJobId[active[i].id];
                              if (inv == null) return active[i].complaint;
                              final payment = inv.computedPaymentStatus().name;
                              final method =
                                  inv.invoice.requestedPaymentMethod?.name;
                              final methodLabel = method == null
                                  ? ''
                                  : ' • ${method.toUpperCase()}';
                              return '${active[i].complaint}\nPembayaran: ${payment.toUpperCase()}$methodLabel';
                            }(),
                            icon: Icons.track_changes_rounded,
                            trailing: _StatusChip(
                              label: active[i].status.label,
                              color: _jobStatusColor(context, active[i].status),
                            ),
                            onTap: () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => _JobDetailSheet(job: active[i]),
                              );
                            },
                          ),
                          if (i != active.length - 1)
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Riwayat'),
        const SizedBox(height: 10),
        Card(
          child: history.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum ada riwayat.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < history.length; i++)
                      Column(
                        children: [
                          _ListRow(
                            title: history[i].id.toUpperCase(),
                            subtitle: history[i].complaint,
                            icon: Icons.check_circle_rounded,
                            trailing: const _StatusChip(
                              label: 'Done',
                              color: Colors.green,
                            ),
                            onTap: () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) =>
                                    _JobDetailSheet(job: history[i]),
                              );
                            },
                          ),
                          if (i != history.length - 1)
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

Color _jobStatusColor(BuildContext context, JobStatus status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    JobStatus.draft => scheme.tertiary,
    JobStatus.inProgress => scheme.primary,
    JobStatus.done => Colors.green,
    JobStatus.cancelled => scheme.error,
  };
}

class _JobDetailSheet extends StatelessWidget {
  const _JobDetailSheet({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final role = state.profile?.role;
    final parts = state.listJobParts(job.id);
    final partsMaster = state.listParts();
    final partById = {for (final p in partsMaster) p.id: p};
    InvoiceSummary? invoice;
    for (final s in state.listInvoices()) {
      if (s.invoice.jobId == job.id) {
        invoice = s;
        break;
      }
    }
    final requestedMethod = invoice?.invoice.requestedPaymentMethod;

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              job.id.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            _StatusChip(
              label: job.status.label,
              color: _jobStatusColor(context, job.status),
            ),
            if (role == AppRole.admin) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (job.status == JobStatus.draft)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await context.read<AppState>().updateJobStatus(
                              jobId: job.id,
                              status: JobStatus.inProgress,
                            );
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Job dimulai')),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Mulai'),
                      ),
                    ),
                  if (job.status == JobStatus.inProgress)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await context.read<AppState>().updateJobStatus(
                              jobId: job.id,
                              status: JobStatus.done,
                            );
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Job selesai')),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Selesai'),
                      ),
                    ),
                  if (job.status == JobStatus.draft ||
                      job.status == JobStatus.inProgress)
                    const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => _JobAddPartSheet(jobId: job.id),
                        );
                      },
                      icon: const Icon(Icons.playlist_add_rounded),
                      label: const Text('Tambah Part'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Text(
                  job.complaint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.78),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SectionHeader(
              title: 'Detail Servis',
              trailing: role == AppRole.admin
                  ? TextButton(
                      onPressed: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => _JobServiceInfoSheet(job: job),
                        );
                      },
                      child: const Text('Edit'),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoRow(
                      label: 'Prioritas',
                      value: job.priority?.label ?? '—',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Estimasi',
                      value: job.etaMinutes == null
                          ? '—'
                          : '${job.etaMinutes} menit',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tindakan Servis',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (job.serviceActions.isEmpty)
                      Text(
                        'Belum ada tindakan dicatat.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final a in job.serviceActions)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '• $a',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (requestedMethod != null) ...[
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      Icon(
                        requestedMethod == PaymentMethod.transfer
                            ? Icons.account_balance_rounded
                            : Icons.payments_rounded,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          requestedMethod == PaymentMethod.transfer
                              ? 'Metode bayar dipilih: Transfer'
                              : 'Metode bayar dipilih: Tunai',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const _SectionHeader(title: 'Part Terpakai'),
            const SizedBox(height: 10),
            Card(
              child: parts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Belum ada part dicatat.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < parts.length; i++)
                          Column(
                            children: [
                              _ListRow(
                                title: () {
                                  final part = partById[parts[i].partId];
                                  if (part == null) {
                                    return parts[i].partId;
                                  }
                                  return '${part.sku} • ${part.name}';
                                }(),
                                subtitle: 'Qty ${parts[i].qty}',
                                icon: Icons.inventory_2_rounded,
                                trailing: _StatusChip(
                                  label: 'x${parts[i].qty}',
                                  color: scheme.primary,
                                ),
                              ),
                              if (i != parts.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 14,
                                  endIndent: 14,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.10,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            const _SectionHeader(title: 'Invoice'),
            const SizedBox(height: 10),
            Card(
              child: invoice == null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Belum ada invoice.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface.withValues(alpha: 0.78),
                        ),
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final inv = invoice!;
                        final method = inv.invoice.requestedPaymentMethod?.name;
                        final methodText = method == null
                            ? ''
                            : ' • ${method.toUpperCase()}';
                        return _ListRow(
                          title:
                              '${inv.invoice.id.toUpperCase()} • ${_fmtRp(inv.invoice.total)}',
                          subtitle:
                              '${inv.invoice.status.label} • ${inv.computedPaymentStatus().name.toUpperCase()}$methodText',
                          icon: Icons.receipt_long_rounded,
                          trailing: _StatusChip(
                            label: inv.computedPaymentStatus().name,
                            color: _paymentColor(
                              context,
                              inv.computedPaymentStatus(),
                            ),
                          ),
                          onTap: () async {
                            final mode = switch (role) {
                              AppRole.admin => _InvoiceSheetMode.admin,
                              AppRole.kasir => _InvoiceSheetMode.cashier,
                              _ => _InvoiceSheetMode.customer,
                            };
                            await showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (_) =>
                                  _InvoiceDetailSheet(summary: inv, mode: mode),
                            );
                          },
                        );
                      },
                    ),
            ),
            if ((role == AppRole.kasir || role == AppRole.admin) &&
                job.status != JobStatus.cancelled) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final created = await context
                        .read<AppState>()
                        .generateInvoiceFromJob(jobId: job.id);
                    if (!context.mounted) {
                      return;
                    }
                    final mode = role == AppRole.admin
                        ? _InvoiceSheetMode.admin
                        : _InvoiceSheetMode.cashier;
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) =>
                          _InvoiceDetailSheet(summary: created, mode: mode),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
                icon: const Icon(Icons.receipt_long_rounded),
                label: Text(
                  invoice == null ? 'Siapkan Invoice' : 'Refresh Invoice',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JobServiceInfoSheet extends StatefulWidget {
  const _JobServiceInfoSheet({required this.job});

  final Job job;

  @override
  State<_JobServiceInfoSheet> createState() => _JobServiceInfoSheetState();
}

class _JobServiceInfoSheetState extends State<_JobServiceInfoSheet> {
  late ServicePriority _priority;
  final _etaController = TextEditingController();
  final _actionsController = TextEditingController();
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _priority = widget.job.priority ?? ServicePriority.rendah;
    _etaController.text = widget.job.etaMinutes?.toString() ?? '';
    _actionsController.text = widget.job.serviceActions.join('\n');
    _noteController.text = widget.job.note ?? '';
  }

  @override
  void dispose() {
    _etaController.dispose();
    _actionsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Detail Servis',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ServicePriority>(
              initialValue: _priority,
              items: [
                for (final p in ServicePriority.values)
                  DropdownMenuItem(value: p, child: Text(p.label)),
              ],
              onChanged: _loading
                  ? null
                  : (v) => setState(() => _priority = v!),
              decoration: const InputDecoration(labelText: 'Prioritas'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _etaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimasi (menit)',
                hintText: 'contoh: 45',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _actionsController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Tindakan servis (1 baris = 1 tindakan)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan internal',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      setState(() => _loading = true);
                      try {
                        final etaStr = _etaController.text.trim();
                        final eta = etaStr.isEmpty
                            ? null
                            : int.tryParse(etaStr);
                        final actions = _actionsController.text
                            .split('\n')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();
                        await context.read<AppState>().updateJobServiceInfo(
                          jobId: widget.job.id,
                          priority: _priority,
                          etaMinutes: eta,
                          serviceActions: actions,
                          note: _noteController.text.trim(),
                        );
                        if (!mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Detail servis disimpan'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobAddPartSheet extends StatefulWidget {
  const _JobAddPartSheet({required this.jobId});

  final String jobId;

  @override
  State<_JobAddPartSheet> createState() => _JobAddPartSheetState();
}

class _JobAddPartSheetState extends State<_JobAddPartSheet> {
  String? _partId;
  final _qtyController = TextEditingController(text: '1');
  bool _loading = false;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final parts = state.listParts().where((p) => p.isActive).toList()
      ..sort((a, b) => a.sku.compareTo(b.sku));
    _partId ??= parts.isNotEmpty ? parts.first.id : null;
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tambah Part Terpakai',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _partId,
            items: [
              for (final p in parts)
                DropdownMenuItem(
                  value: p.id,
                  child: Text('${p.sku} • ${p.name} (stok ${p.stockOnHand})'),
                ),
            ],
            onChanged: _loading ? null : (v) => setState(() => _partId = v),
            decoration: const InputDecoration(labelText: 'Sparepart'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Qty'),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _loading
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final partId = _partId;
                    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
                    if (partId == null) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Part wajib dipilih')),
                      );
                      return;
                    }
                    if (qty <= 0) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Qty tidak valid')),
                      );
                      return;
                    }
                    setState(() => _loading = true);
                    try {
                      await context.read<AppState>().addJobPart(
                        jobId: widget.jobId,
                        partId: partId,
                        qty: qty,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Part ditambahkan')),
                      );
                      Navigator.of(context).pop();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(_friendlyError(e))),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _loading = false);
                      }
                    }
                  },
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _JobPickAndAddPartSheet extends StatefulWidget {
  const _JobPickAndAddPartSheet();

  @override
  State<_JobPickAndAddPartSheet> createState() =>
      _JobPickAndAddPartSheetState();
}

class _JobPickAndAddPartSheetState extends State<_JobPickAndAddPartSheet> {
  String? _jobId;
  String? _partId;
  final _qtyController = TextEditingController(text: '1');
  bool _loading = false;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final jobs = state.listJobs();
    final parts = state.listParts().where((p) => p.isActive).toList()
      ..sort((a, b) => a.sku.compareTo(b.sku));
    _jobId ??= jobs.isNotEmpty ? jobs.first.id : null;
    _partId ??= parts.isNotEmpty ? parts.first.id : null;
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tambah Part ke Job',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _jobId,
              items: [
                for (final j in jobs)
                  DropdownMenuItem(
                    value: j.id,
                    child: Text(j.id.toUpperCase()),
                  ),
              ],
              onChanged: _loading ? null : (v) => setState(() => _jobId = v),
              decoration: const InputDecoration(labelText: 'Job'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _partId,
              items: [
                for (final p in parts)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.sku} • ${p.name} (stok ${p.stockOnHand})'),
                  ),
              ],
              onChanged: _loading ? null : (v) => setState(() => _partId = v),
              decoration: const InputDecoration(labelText: 'Sparepart'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Qty'),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final jobId = _jobId;
                      final partId = _partId;
                      final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
                      if (jobId == null || partId == null) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Job & part wajib dipilih'),
                          ),
                        );
                        return;
                      }
                      if (qty <= 0) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Qty tidak valid')),
                        );
                        return;
                      }
                      setState(() => _loading = true);
                      try {
                        await context.read<AppState>().addJobPart(
                          jobId: jobId,
                          partId: partId,
                          qty: qty,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Part ditambahkan')),
                        );
                        Navigator.of(context).pop();
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _loading = false);
                        }
                      }
                    },
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerBooking extends StatelessWidget {
  const _CustomerBooking();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final bookings = state.listBookings();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int remaining(String time) {
      final used = bookings
          .where(
            (b) =>
                b.countsForQuota &&
                DateTime(
                      b.bookingDate.year,
                      b.bookingDate.month,
                      b.bookingDate.day,
                    ) ==
                    today &&
                b.bookingTime == time,
          )
          .length;
      return (4 - used).clamp(0, 4);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const _BookingCreateSheet(),
                  );
                },
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Buat Booking'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Aturan Booking'),
                      content: const Text(
                        'Slot: 08:00, 10:00, 13:00, 15:00\n'
                        'Max 4 booking per slot\n'
                        'Pending mengunci kuota\n'
                        'Bengkel tutup hari Jumat',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Tutup'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline_rounded),
                label: const Text('Aturan'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionHeader(title: 'Slot Hari Ini'),
                const SizedBox(height: 10),
                _SlotRow(time: '08:00', remaining: remaining('08:00')),
                const SizedBox(height: 8),
                _SlotRow(time: '10:00', remaining: remaining('10:00')),
                const SizedBox(height: 8),
                _SlotRow(time: '13:00', remaining: remaining('13:00')),
                const SizedBox(height: 8),
                _SlotRow(time: '15:00', remaining: remaining('15:00')),
                const SizedBox(height: 10),
                Text(
                  state.isMockMode
                      ? 'Mode demo (tanpa backend). Data disimpan di HP.'
                      : 'Mode Supabase (data live).',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Booking Saya'),
        const SizedBox(height: 10),
        Card(
          child: bookings.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum ada booking.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < bookings.length; i++)
                      Column(
                        children: [
                          _ListRow(
                            title:
                                '${bookings[i].type.label} • ${bookings[i].status.label}',
                            subtitle:
                                '${_fmtDate(bookings[i].bookingDate)}, ${bookings[i].bookingTime} • ${bookings[i].complaint}',
                            icon: bookings[i].type == BookingType.modif
                                ? Icons.speed_rounded
                                : Icons.event_note_rounded,
                            trailing: _StatusChip(
                              label: bookings[i].status.label,
                              color: _statusColor(context, bookings[i].status),
                            ),
                            onTap: () async {
                              if (bookings[i].status == BookingStatus.pending) {
                                await showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  builder: (_) => _BookingRescheduleSheet(
                                    booking: bookings[i],
                                  ),
                                );
                                return;
                              }
                              _toast(
                                context,
                                'Booking sudah ${bookings[i].status.label.toLowerCase()}.',
                              );
                            },
                          ),
                          if (i != bookings.length - 1)
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

String _fmtDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

String _fmtRp(num value) {
  final n = value.round();
  final s = n.abs().toString();
  final rev = s.split('').reversed.toList();
  final buf = StringBuffer();
  for (var i = 0; i < rev.length; i++) {
    if (i != 0 && i % 3 == 0) {
      buf.write('.');
    }
    buf.write(rev[i]);
  }
  final grouped = buf.toString().split('').reversed.join();
  final sign = n < 0 ? '-' : '';
  return 'Rp $sign$grouped';
}

Color _statusColor(BuildContext context, BookingStatus status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    BookingStatus.pending => scheme.tertiary,
    BookingStatus.confirmed => Colors.green,
    BookingStatus.rejected => scheme.error,
    BookingStatus.checkedIn => scheme.primary,
    BookingStatus.cancelled => scheme.error,
    BookingStatus.done => Colors.green,
  };
}

class _BookingCreateSheet extends StatefulWidget {
  const _BookingCreateSheet({this.initialType, this.lockType = false});

  final BookingType? initialType;
  final bool lockType;

  @override
  State<_BookingCreateSheet> createState() => _BookingCreateSheetState();
}

class _BookingCreateSheetState extends State<_BookingCreateSheet> {
  final _complaintController = TextEditingController();
  final _targetCcController = TextEditingController();
  final _strokeMmController = TextEditingController();
  BookingType _type = BookingType.service;
  String? _serviceTypeId;
  String? _serviceSubtypeId;
  String _usage = 'Harian Irit';
  String _fuel = 'injeksi';
  String _cooling = 'udara';
  ModCalcResult? _upgradeResult;
  final Map<String, String> _upgradeBomPartIdByKey = {};
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _time = BookingRules.openSlots.first;
  String? _vehicleId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? BookingType.service;
    _upgradeResult = null;
    _strokeMmController.text = '57';
    if (_date.weekday == DateTime.friday) {
      _date = _date.add(const Duration(days: 1));
    }
    if (_type == BookingType.modif) {
      _time = '08:00';
    }
    if (_type == BookingType.service) {
      _serviceTypeId = null;
      _serviceSubtypeId = null;
    }
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _targetCcController.dispose();
    _strokeMmController.dispose();
    super.dispose();
  }

  String _bomKey(BomItem item) {
    final s = item.sku?.trim();
    if (s != null && s.isNotEmpty) return 'sku:$s';
    return 'name:${item.name}|${item.spec}';
  }

  Future<void> _pickUpgradePartForBomItem({
    required BomItem item,
    required List<Part> parts,
  }) async {
    final picked = await showModalBottomSheet<Part>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PartPickerSheet(
        title: 'Pilih Part dari Stok',
        parts: parts.where((p) => p.isActive).toList(),
        initialQuery: item.sku ?? item.name,
      ),
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _upgradeBomPartIdByKey[_bomKey(item)] = picked.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final vehicles = state.listVehicles();
    final parts = state.listParts();
    final serviceSubtypeParts = state.listAllServiceSubtypeParts();
    final catalogError = state.serviceCatalogError;
    final subtypesAll = state
        .listServiceSubtypes()
        .where((s) => s.isActive)
        .toList();
    final scheme = Theme.of(context).colorScheme;
    final partById = {for (final p in parts) p.id: p};

    List<ServiceSubtypePart> requiredSubtypeParts(ServiceSubtype? subtype) {
      if (subtype == null || subtype.id.isEmpty) return const [];
      return serviceSubtypeParts
          .where((x) => x.serviceSubtypeId == subtype.id && !x.isOptional)
          .toList();
    }

    num requiredSubtypePartsTotal(ServiceSubtype? subtype) {
      num total = 0;
      for (final item in requiredSubtypeParts(subtype)) {
        final part = partById[item.partId];
        if (part == null) continue;
        total += part.sellPrice * item.qty;
      }
      return total;
    }

    num estimatedSubtypeTotal(ServiceSubtype? subtype) {
      if (subtype == null) return 0;
      return subtype.baseLaborPrice + requiredSubtypePartsTotal(subtype);
    }

    Part? matchedUpgradePart(BomItem item) {
      final key = _bomKey(item);
      final selectedPartId = _upgradeBomPartIdByKey[key];
      if (selectedPartId != null) {
        for (final p in parts) {
          if (p.id == selectedPartId) return p;
        }
      }
      final sku = item.sku?.trim();
      if (sku != null && sku.isNotEmpty) {
        for (final p in parts) {
          if (p.sku.toLowerCase() == sku.toLowerCase()) return p;
        }
      }
      return null;
    }

    num upgradeBomPartsTotal(ModCalcResult? result) {
      if (result == null) return 0;
      num total = 0;
      for (final item in result.bom) {
        final matched = matchedUpgradePart(item);
        if (matched == null) continue;
        total += matched.sellPrice * item.qty;
      }
      return total;
    }

    int upgradeLaborPriceForTargetCc(double? targetCc) {
      final base = switch (_usage) {
        'Harian Irit' => 200000,
        'Harian Kenceng' => 250000,
        'Touring' => 250000,
        'Race' => 300000,
        _ => 200000,
      };
      final t = (targetCc ?? 0).round();
      if (t <= 0) return base;
      final extra = ((t - 150).clamp(0, 200)) * 1000;
      return base + extra;
    }

    if (_type == BookingType.service) {
      bool isOverhaul(ServiceSubtype s) {
        return s.name.toLowerCase().contains('overhaul');
      }

      final allowed = [...subtypesAll]
        ..sort((a, b) => a.name.compareTo(b.name));
      final allowedWithPrice = allowed
          .where((s) => s.baseLaborPrice > 0 && !isOverhaul(s))
          .toList();
      if (_serviceSubtypeId != null) {
        final stillExists = allowed.any((s) => s.id == _serviceSubtypeId);
        final stillSelectable = allowedWithPrice.any(
          (s) => s.id == _serviceSubtypeId,
        );
        if (!stillExists || !stillSelectable) {
          _serviceSubtypeId = null;
        }
      }
      _serviceSubtypeId ??= allowedWithPrice.isNotEmpty
          ? allowedWithPrice.first.id
          : null;
      _serviceTypeId = _serviceSubtypeId == null
          ? null
          : (() {
              for (final s in allowed) {
                if (s.id == _serviceSubtypeId) return s.serviceTypeId;
              }
              return null;
            })();
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Buat Booking',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            widget.lockType
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          _type == BookingType.service
                              ? 'Service'
                              : 'Upgrade Mesin',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      _StatusChip(label: _type.label, color: scheme.primary),
                    ],
                  )
                : DropdownButtonFormField<BookingType>(
                    initialValue: _type,
                    items: const [
                      DropdownMenuItem(
                        value: BookingType.service,
                        child: Text('Service'),
                      ),
                      DropdownMenuItem(
                        value: BookingType.modif,
                        child: Text('Upgrade Mesin'),
                      ),
                    ],
                    onChanged: _loading
                        ? null
                        : (v) => setState(() {
                            _type = v ?? BookingType.service;
                            _upgradeResult = null;
                            if (_type == BookingType.service) {
                              _serviceTypeId = null;
                              _serviceSubtypeId = null;
                              if (!BookingRules.openSlots.contains(_time)) {
                                _time = BookingRules.openSlots.first;
                              }
                            } else {
                              _time = '08:00';
                            }
                          }),
                    decoration: const InputDecoration(labelText: 'Tipe'),
                  ),
            const SizedBox(height: 12),
            if (_type == BookingType.service)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (subtypesAll.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              catalogError == null
                                  ? 'Master servis belum diisi di database. Tambahkan data di service_subtypes.'
                                  : 'Master servis gagal dimuat. Pastikan tabel service_subtypes ada, berisi data, dan policy SELECT mengizinkan authenticated users.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.72,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            if (catalogError != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                catalogError,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.error.withValues(
                                        alpha: 0.90,
                                      ),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _loading
                                  ? null
                                  : () async {
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      try {
                                        await context
                                            .read<AppState>()
                                            .refreshServiceCatalog();
                                      } catch (e) {
                                        messenger.showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Muat Ulang Master Servis'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Builder(
                      builder: (context) {
                        String displayName(ServiceSubtype s) {
                          final n = s.name.trim();
                          if (n.toLowerCase().contains('tune up')) {
                            return 'Peremajaan Mesin (Tune Up)';
                          }
                          return n;
                        }

                        final st = _serviceSubtypeId == null
                            ? null
                            : subtypesAll.firstWhere(
                                (x) => x.id == _serviceSubtypeId,
                                orElse: () => subtypesAll.first,
                              );
                        final priceLabel = st == null
                            ? ''
                            : 'Estimasi total ${_fmtRp(estimatedSubtypeTotal(st))}';
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _SectionHeader(title: 'Servis'),
                                const SizedBox(height: 10),
                                _ListRow(
                                  title: st == null
                                      ? 'Belum dipilih'
                                      : displayName(st),
                                  subtitle: st == null
                                      ? 'Pilih servis untuk melihat estimasi biaya.'
                                      : priceLabel,
                                  icon: Icons.handyman_rounded,
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: _loading
                                      ? null
                                      : () async {
                                          final picked =
                                              await showModalBottomSheet<
                                                ServiceSubtype
                                              >(
                                                context: context,
                                                isScrollControlled: true,
                                                useSafeArea: true,
                                                builder: (_) =>
                                                    _ServicePickerSheet(
                                                      title: 'Pilih Servis',
                                                      parts: parts,
                                                      serviceSubtypeParts:
                                                          serviceSubtypeParts,
                                                      subtypes: [...subtypesAll]
                                                        ..sort(
                                                          (a, b) =>
                                                              a.name.compareTo(
                                                                b.name,
                                                              ),
                                                        ),
                                                    ),
                                              );
                                          if (picked == null) return;
                                          if (!context.mounted) return;
                                          setState(() {
                                            _serviceSubtypeId = picked.id;
                                            _serviceTypeId =
                                                picked.serviceTypeId;
                                          });
                                        },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        String displayName(ServiceSubtype s) {
                          final n = s.name.trim();
                          if (n.toLowerCase().contains('tune up')) {
                            return 'Peremajaan Mesin (Tune Up)';
                          }
                          return n;
                        }

                        final st = _serviceSubtypeId == null
                            ? null
                            : subtypesAll.firstWhere(
                                (x) => x.id == _serviceSubtypeId,
                                orElse: () => subtypesAll.first,
                              );
                        if (st == null || st.id.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        if (st.baseLaborPrice <= 0) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Harga jasa untuk servis ini belum diisi. Pilih servis lain.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          );
                        }
                        final defaultParts = requiredSubtypeParts(st);
                        final partsTotal = requiredSubtypePartsTotal(st);
                        final estimatedTotal = estimatedSubtypeTotal(st);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _SectionHeader(title: 'Rincian Harga'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayName(st),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      _fmtRp(st.baseLaborPrice),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Jasa',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      _fmtRp(st.baseLaborPrice),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (defaultParts.isEmpty)
                                  Text(
                                    'Part default: Rp 0',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurface.withValues(
                                            alpha: 0.72,
                                          ),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  )
                                else ...[
                                  Text(
                                    'Part bawaan servis:',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurface.withValues(
                                            alpha: 0.72,
                                          ),
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  for (final item in defaultParts)
                                    Builder(
                                      builder: (_) {
                                        final part = partById[item.partId];
                                        final unitPrice = part?.sellPrice ?? 0;
                                        final lineTotal = unitPrice * item.qty;
                                        final label = part == null
                                            ? item.partId
                                            : '${part.name} x${item.qty}';
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  label,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                              Text(
                                                _fmtRp(lineTotal),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Total Part',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurface
                                                    .withValues(alpha: 0.72),
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        _fmtRp(partsTotal),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Divider(
                                  height: 1,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.10,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Estimasi Total',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      _fmtRp(estimatedTotal),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ],
                                ),
                                if (st.description.trim().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    st.description,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurface.withValues(
                                            alpha: 0.72,
                                          ),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _strokeMmController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) =>
                              setState(() => _upgradeResult = null),
                          decoration: const InputDecoration(
                            labelText: 'Stroke (mm)',
                            hintText: 'Contoh: 57',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _targetCcController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) =>
                              setState(() => _upgradeResult = null),
                          decoration: const InputDecoration(
                            labelText: 'Target CC',
                            hintText: 'Contoh: 180',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _usage,
                    items: const [
                      DropdownMenuItem(
                        value: 'Harian Irit',
                        child: Text('Harian Irit'),
                      ),
                      DropdownMenuItem(
                        value: 'Harian Kenceng',
                        child: Text('Harian Kenceng'),
                      ),
                      DropdownMenuItem(
                        value: 'Touring',
                        child: Text('Touring'),
                      ),
                      DropdownMenuItem(value: 'Race', child: Text('Race')),
                    ],
                    onChanged: _loading
                        ? null
                        : (v) => setState(() => _usage = v ?? 'Harian Irit'),
                    decoration: const InputDecoration(
                      labelText: 'Target Pemakaian',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _fuel,
                          items: const [
                            DropdownMenuItem(
                              value: 'injeksi',
                              child: Text('Injeksi'),
                            ),
                            DropdownMenuItem(
                              value: 'karbu',
                              child: Text('Karbu'),
                            ),
                          ],
                          onChanged: _loading
                              ? null
                              : (v) => setState(() {
                                  _fuel = v ?? 'injeksi';
                                  _upgradeResult = null;
                                }),
                          decoration: const InputDecoration(
                            labelText: 'Sistem BBM',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _cooling,
                          items: const [
                            DropdownMenuItem(
                              value: 'udara',
                              child: Text('Udara'),
                            ),
                            DropdownMenuItem(
                              value: 'cair',
                              child: Text('Cair'),
                            ),
                          ],
                          onChanged: _loading
                              ? null
                              : (v) => setState(() {
                                  _cooling = v ?? 'udara';
                                  _upgradeResult = null;
                                }),
                          decoration: const InputDecoration(
                            labelText: 'Pendingin',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final targetCc = double.tryParse(
                        _targetCcController.text.trim().replaceAll(',', '.'),
                      );
                      final labor = upgradeLaborPriceForTargetCc(targetCc);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SectionHeader(
                                title: 'Aturan Upgrade Mesin',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hanya tersedia jam 08:00, maksimal 1 pekerjaan upgrade per hari, dan montir hanya boleh 1 pekerjaan per hari.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Estimasi Jasa',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    _fmtRp(labor),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () {
                            final targetCc = double.tryParse(
                              _targetCcController.text.trim().replaceAll(
                                ',',
                                '.',
                              ),
                            );
                            final stroke = double.tryParse(
                              _strokeMmController.text.trim().replaceAll(
                                ',',
                                '.',
                              ),
                            );
                            if (stroke == null || stroke <= 0) {
                              _toast(context, 'Stroke wajib diisi');
                              return;
                            }
                            if (targetCc == null || targetCc <= 0) {
                              _toast(context, 'Target CC wajib diisi');
                              return;
                            }
                            final requiredBore =
                                ModCalculator.requiredBoreForTargetCc(
                                  targetCc: targetCc,
                                  strokeMm: stroke,
                                );
                            setState(() {
                              _upgradeResult =
                                  ModCalculator.buildRecommendation(
                                    boreMm: requiredBore,
                                    strokeMm: stroke,
                                    stockCc: 0,
                                    usage: _usage,
                                    fuelSystem: _fuel,
                                    cooling: _cooling,
                                  );
                            });
                          },
                    icon: const Icon(Icons.calculate_rounded),
                    label: const Text('Preview Rekomendasi'),
                  ),
                  if (_upgradeResult != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${_upgradeResult!.cc.toStringAsFixed(1)} cc',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                _StatusChip(
                                  label: 'RON ${_upgradeResult!.minRon}+',
                                  color: scheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _upgradeResult!.compressionNote,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.76,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _upgradeResult!.recommendationNote,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.68,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          for (var i = 0; i < _upgradeResult!.bom.length; i++)
                            Column(
                              children: [
                                Builder(
                                  builder: (context) {
                                    final item = _upgradeResult!.bom[i];
                                    final matched = matchedUpgradePart(item);

                                    final stock = matched?.stockOnHand;
                                    late final Color statusColor;
                                    late final String statusLabel;
                                    if (matched == null) {
                                      statusColor = scheme.onSurface.withValues(
                                        alpha: 0.50,
                                      );
                                      statusLabel = 'Pilih';
                                    } else if (stock == null || stock <= 0) {
                                      statusColor = scheme.error;
                                      statusLabel = 'Kosong';
                                    } else if (stock <= matched.minStock) {
                                      statusColor = Colors.orange;
                                      statusLabel = 'Low';
                                    } else {
                                      statusColor = Colors.green;
                                      statusLabel = 'Ready';
                                    }

                                    final subtitleParts = <String>[
                                      matched?.sku ?? (item.sku ?? '-'),
                                      'Qty ${item.qty}',
                                      if (matched != null)
                                        'Harga ${_fmtRp(matched.sellPrice)}',
                                      if (matched != null)
                                        'Subtotal ${_fmtRp(matched.sellPrice * item.qty)}',
                                      if (stock != null) 'Stok $stock',
                                    ];

                                    return _ListRow(
                                      title: '${item.name} • ${item.spec}',
                                      subtitle: subtitleParts.join(' • '),
                                      icon: Icons.inventory_2_rounded,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _StatusChip(
                                            label: statusLabel,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            onPressed: _loading
                                                ? null
                                                : () =>
                                                      _pickUpgradePartForBomItem(
                                                        item: item,
                                                        parts: parts,
                                                      ),
                                            icon: const Icon(
                                              Icons.swap_horiz_rounded,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: _loading
                                          ? null
                                          : () => _pickUpgradePartForBomItem(
                                              item: item,
                                              parts: parts,
                                            ),
                                    );
                                  },
                                ),
                                if (i != _upgradeResult!.bom.length - 1)
                                  Divider(
                                    height: 1,
                                    indent: 14,
                                    endIndent: 14,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.10,
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final targetCc = double.tryParse(
                          _targetCcController.text.trim().replaceAll(',', '.'),
                        );
                        final labor = upgradeLaborPriceForTargetCc(targetCc);
                        final partsTotal = upgradeBomPartsTotal(_upgradeResult);
                        final grandTotal = labor + partsTotal;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _SectionHeader(
                                  title: 'Rincian Biaya Upgrade',
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Jasa Upgrade',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      _fmtRp(labor),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Total Part',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      _fmtRp(partsTotal),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Divider(
                                  height: 1,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.10,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Estimasi Total Upgrade',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      _fmtRp(grandTotal),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final options = _type == BookingType.modif
                    ? const <String>['08:00']
                    : BookingRules.openSlots;
                final initialTime = options.contains(_time)
                    ? _time
                    : options.first;
                return DropdownButtonFormField<String>(
                  initialValue: initialTime,
                  items: [
                    for (final t in options)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: _loading || _type == BookingType.modif
                      ? null
                      : (v) => setState(() => _time = v ?? options.first),
                  decoration: const InputDecoration(labelText: 'Slot Jam'),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                        initialDate: _date,
                        selectableDayPredicate: (d) =>
                            d.weekday != DateTime.friday,
                      );
                      if (picked == null) return;
                      setState(() => _date = picked);
                    },
              icon: const Icon(Icons.date_range_rounded),
              label: Text('Tanggal: ${_fmtDate(_date)}'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _vehicleId,
              items: [
                for (final v in vehicles)
                  DropdownMenuItem(
                    value: v.id,
                    child: Text('${v.plateNumber} • ${v.brand} ${v.model}'),
                  ),
              ],
              onChanged: _loading
                  ? null
                  : (v) => setState(() => _vehicleId = v),
              decoration: const InputDecoration(labelText: 'Kendaraan'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _complaintController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Keluhan / Catatan',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _loading = true);
                      try {
                        final note = _complaintController.text.trim();
                        final parsedTargetCc = double.tryParse(
                          _targetCcController.text.trim().replaceAll(',', '.'),
                        );
                        if (_type == BookingType.modif &&
                            (parsedTargetCc == null || parsedTargetCc <= 0)) {
                          _toast(context, 'Target CC wajib diisi');
                          return;
                        }
                        if (_type == BookingType.service) {
                          ServiceSubtype? st;
                          if (_serviceSubtypeId != null) {
                            for (final s in subtypesAll) {
                              if (s.id == _serviceSubtypeId) {
                                st = s;
                                break;
                              }
                            }
                          }
                          if (st != null && st.baseLaborPrice <= 0) {
                            _toast(
                              context,
                              'Harga jasa belum diisi. Pilih servis lain.',
                            );
                            return;
                          }
                        }
                        final complaint = () {
                          if (_type == BookingType.service) {
                            if (subtypesAll.isEmpty) {
                              return note.isEmpty ? 'Servis' : 'Servis • $note';
                            }
                            final subtypeName = _serviceSubtypeId == null
                                ? ''
                                : () {
                                    final hit = subtypesAll
                                        .where((s) => s.id == _serviceSubtypeId)
                                        .toList();
                                    if (hit.isEmpty) return '';
                                    final raw = hit.first.name.trim();
                                    if (raw.toLowerCase().contains('tune up')) {
                                      return 'Peremajaan Mesin (Tune Up)';
                                    }
                                    return raw;
                                  }();
                            final base = subtypeName.isEmpty
                                ? 'Servis'
                                : 'Servis • $subtypeName';
                            return note.isEmpty ? base : '$base • $note';
                          }
                          final parts = <String>['Upgrade Mesin'];
                          if (parsedTargetCc != null && parsedTargetCc > 0) {
                            parts.add(
                              'Target ${parsedTargetCc.toStringAsFixed(0)}cc',
                            );
                          }
                          final stroke = double.tryParse(
                            _strokeMmController.text.trim().replaceAll(
                              ',',
                              '.',
                            ),
                          );
                          if (stroke != null && stroke > 0) {
                            parts.add('Stroke ${stroke.toStringAsFixed(0)}mm');
                          }
                          if (note.isNotEmpty) parts.add(note);
                          return parts.join(' • ');
                        }();
                        final upgradeBom = () {
                          final bom = _upgradeResult?.bom;
                          if (bom == null || bom.isEmpty) return null;
                          final out = <Map<String, Object?>>[];
                          for (final item in bom) {
                            final key = _bomKey(item);
                            final matched = matchedUpgradePart(item);
                            out.add({
                              'key': key,
                              'sku': item.sku,
                              'name': item.name,
                              'spec': item.spec,
                              'qty': item.qty,
                              'inventory_part_id': matched?.id,
                              'inventory_sku': matched?.sku,
                              'inventory_name': matched?.name,
                              'inventory_sell_price': matched?.sellPrice,
                              'estimated_line_total': matched == null
                                  ? null
                                  : matched.sellPrice * item.qty,
                              'inventory_stock_on_hand': matched?.stockOnHand,
                            });
                          }
                          return out;
                        }();
                        final upgradeLaborPrice = _type != BookingType.modif
                            ? 0
                            : upgradeLaborPriceForTargetCc(parsedTargetCc);
                        final upgradePartsPrice = _type != BookingType.modif
                            ? 0
                            : upgradeBomPartsTotal(_upgradeResult);
                        await context.read<AppState>().createBooking(
                          type: _type,
                          date: _date,
                          time: _time,
                          complaint: complaint,
                          vehicleId: _vehicleId,
                          serviceTypeId: _type == BookingType.service
                              ? _serviceTypeId
                              : null,
                          serviceSubtypeId: _type == BookingType.service
                              ? _serviceSubtypeId
                              : null,
                          modifPayload: _type == BookingType.modif
                              ? {
                                  'source': 'manual',
                                  'kind': 'upgrade_mesin',
                                  'labor_price': upgradeLaborPrice,
                                  'stroke_mm': double.tryParse(
                                    _strokeMmController.text.trim().replaceAll(
                                      ',',
                                      '.',
                                    ),
                                  ),
                                  'usage': _usage,
                                  'fuel_system': _fuel,
                                  'cooling': _cooling,
                                  'parts_price': upgradePartsPrice,
                                  'estimated_total':
                                      upgradeLaborPrice + upgradePartsPrice,
                                  if (parsedTargetCc != null &&
                                      parsedTargetCc > 0)
                                    'target_cc': parsedTargetCc,
                                  if (_upgradeResult != null)
                                    'calc': _upgradeResult!.toPayload(),
                                  if (upgradeBom != null)
                                    'inventory_bom': upgradeBom,
                                }
                              : null,
                        );
                        if (!mounted) {
                          return;
                        }
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Booking dibuat')),
                        );
                      } catch (e) {
                        if (!mounted) {
                          return;
                        }
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _loading = false);
                        }
                      }
                    },
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CalcMode { fromBoreStroke, targetCcBoreUp }

class _ModCalculatorSheet extends StatefulWidget {
  const _ModCalculatorSheet();

  @override
  State<_ModCalculatorSheet> createState() => _ModCalculatorSheetState();
}

class _ModCalculatorSheetState extends State<_ModCalculatorSheet> {
  _CalcMode _mode = _CalcMode.fromBoreStroke;

  final _boreController = TextEditingController();
  final _strokeController = TextEditingController();
  final _targetCcController = TextEditingController();

  double? _ccResult;
  double? _boreResult;
  double? _strokeResult;
  double? _targetCcResult;

  @override
  void dispose() {
    _boreController.dispose();
    _strokeController.dispose();
    _targetCcController.dispose();
    super.dispose();
  }

  double _parseDouble(TextEditingController c) {
    return double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;
  }

  Future<void> _calculate() async {
    final boreRaw = _parseDouble(_boreController);
    final strokeRaw = _parseDouble(_strokeController);
    final targetCc = _parseDouble(_targetCcController);
    final bore = boreRaw.roundToDouble();
    final stroke = strokeRaw.roundToDouble();

    if (_mode == _CalcMode.fromBoreStroke) {
      if (bore <= 0 || stroke <= 0) {
        _toast(context, 'Bore & stroke wajib diisi');
        return;
      }
      _boreController.text = bore.round().toString();
      _strokeController.text = stroke.round().toString();
      setState(() {
        _boreResult = bore;
        _strokeResult = stroke;
        _targetCcResult = null;
        _ccResult = ModCalculator.calcCc(boreMm: bore, strokeMm: stroke);
      });
      return;
    }

    if (stroke <= 0) {
      _toast(context, 'Stroke wajib diisi');
      return;
    }
    if (targetCc <= 0) {
      _toast(context, 'Target CC wajib diisi');
      return;
    }
    final requiredBore = ModCalculator.requiredBoreForTargetCc(
      targetCc: targetCc,
      strokeMm: stroke,
    );
    final roundedBore = requiredBore.roundToDouble();
    setState(() {
      _boreResult = roundedBore;
      _strokeResult = stroke;
      _targetCcResult = targetCc;
      _ccResult = ModCalculator.calcCc(boreMm: roundedBore, strokeMm: stroke);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kalkulator CC',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_CalcMode>(
              initialValue: _mode,
              items: const [
                DropdownMenuItem(
                  value: _CalcMode.fromBoreStroke,
                  child: Text('Bore + Stroke'),
                ),
                DropdownMenuItem(
                  value: _CalcMode.targetCcBoreUp,
                  child: Text('Target CC'),
                ),
              ],
              onChanged: (v) => setState(() {
                _mode = v ?? _CalcMode.fromBoreStroke;
                _ccResult = null;
                _boreResult = null;
                _strokeResult = null;
                _targetCcResult = null;
              }),
              decoration: const InputDecoration(labelText: 'Mode'),
            ),
            const SizedBox(height: 12),
            if (_mode == _CalcMode.fromBoreStroke) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _boreController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Bore (mm)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _strokeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stroke (mm)',
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              TextField(
                controller: _strokeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stroke (mm)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetCcController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target CC'),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate_rounded),
              label: const Text('Hitung'),
            ),
            if (_ccResult != null &&
                _boreResult != null &&
                _strokeResult != null) ...[
              const SizedBox(height: 16),
              const _SectionHeader(title: 'Hasil'),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_ccResult!.toStringAsFixed(1)} cc',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (_targetCcResult != null)
                            _StatusChip(
                              label: 'Target ${_targetCcResult!.round()}cc',
                              color: scheme.primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Bore',
                        value: '${_boreResult!.round()} mm',
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(
                        label: 'Stroke',
                        value: '${_strokeResult!.round()} mm',
                      ),
                      if (_mode == _CalcMode.targetCcBoreUp) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Bore yang dibutuhkan: ${_boreResult!.round()} mm',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServicePickerSheet extends StatefulWidget {
  const _ServicePickerSheet({
    required this.title,
    required this.subtypes,
    required this.parts,
    required this.serviceSubtypeParts,
  });

  final String title;
  final List<ServiceSubtype> subtypes;
  final List<Part> parts;
  final List<ServiceSubtypePart> serviceSubtypeParts;

  @override
  State<_ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<_ServicePickerSheet> {
  final _qController = TextEditingController();

  @override
  void dispose() {
    _qController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = _qController.text.trim().toLowerCase();
    final partById = {for (final p in widget.parts) p.id: p};

    List<ServiceSubtypePart> requiredSubtypeParts(ServiceSubtype subtype) {
      return widget.serviceSubtypeParts
          .where((x) => x.serviceSubtypeId == subtype.id && !x.isOptional)
          .toList();
    }

    num requiredSubtypePartsTotal(ServiceSubtype subtype) {
      num total = 0;
      for (final item in requiredSubtypeParts(subtype)) {
        final part = partById[item.partId];
        if (part == null) continue;
        total += part.sellPrice * item.qty;
      }
      return total;
    }

    String displayName(ServiceSubtype s) {
      final n = s.name.trim();
      if (n.toLowerCase().contains('tune up'))
        return 'Peremajaan Mesin (Tune Up)';
      return n;
    }

    final filtered = widget.subtypes.where((s) {
      if (s.baseLaborPrice <= 0) return false;
      if (s.name.toLowerCase().contains('overhaul')) return false;
      if (q.isEmpty) return true;
      final hay = '${s.code} ${displayName(s)} ${s.description}'.toLowerCase();
      return hay.contains(q);
    }).toList()..sort((a, b) => displayName(a).compareTo(displayName(b)));

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _qController,
                  decoration: const InputDecoration(
                    labelText: 'Cari Servis',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Servis tidak ditemukan.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.72,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final s = filtered[i];
                              final partsTotal = requiredSubtypePartsTotal(s);
                              final total = s.baseLaborPrice + partsTotal;
                              final subtitle = <String>[
                                'Jasa ${_fmtRp(s.baseLaborPrice)}',
                                'Part ${_fmtRp(partsTotal)}',
                                if (s.description.trim().isNotEmpty)
                                  s.description,
                              ].join(' • ');
                              return Column(
                                children: [
                                  _ListRow(
                                    title: displayName(s),
                                    subtitle: subtitle,
                                    icon: Icons.handyman_rounded,
                                    trailing: _StatusChip(
                                      label: _fmtRp(total),
                                      color: scheme.primary,
                                    ),
                                    onTap: () => Navigator.of(context).pop(s),
                                  ),
                                  if (i != filtered.length - 1)
                                    Divider(
                                      height: 1,
                                      indent: 14,
                                      endIndent: 14,
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.10,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PartPickerSheet extends StatefulWidget {
  const _PartPickerSheet({
    required this.title,
    required this.parts,
    this.initialQuery,
  });

  final String title;
  final List<Part> parts;
  final String? initialQuery;

  @override
  State<_PartPickerSheet> createState() => _PartPickerSheetState();
}

class _PartPickerSheetState extends State<_PartPickerSheet> {
  final _qController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _qController.text = widget.initialQuery?.trim() ?? '';
  }

  @override
  void dispose() {
    _qController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = _qController.text.trim().toLowerCase();
    final filtered = widget.parts.where((p) {
      if (q.isEmpty) return true;
      final hay = '${p.sku} ${p.name} ${p.unit}'.toLowerCase();
      return hay.contains(q);
    }).toList()..sort((a, b) => a.sku.compareTo(b.sku));

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _qController,
                  decoration: const InputDecoration(
                    labelText: 'Cari SKU / Nama',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Part tidak ditemukan.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.72,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final p = filtered[i];
                              final stock = p.stockOnHand;
                              final status = stock <= 0
                                  ? 'Kosong'
                                  : (p.isLowStock ? 'Low' : 'Ready');
                              final color = stock <= 0
                                  ? scheme.error
                                  : (p.isLowStock
                                        ? scheme.tertiary
                                        : Colors.green);
                              return Column(
                                children: [
                                  _ListRow(
                                    title: '${p.sku} • ${p.name}',
                                    subtitle: [
                                      'Stok $stock ${p.unit}',
                                      'Min ${p.minStock}',
                                      'Jual ${_fmtRp(p.sellPrice)}',
                                      'Beli ${_fmtRp(p.buyPrice)}',
                                    ].join(' • '),
                                    icon: Icons.inventory_2_rounded,
                                    trailing: _StatusChip(
                                      label: status,
                                      color: color,
                                    ),
                                    onTap: () => Navigator.of(context).pop(p),
                                  ),
                                  if (i != filtered.length - 1)
                                    Divider(
                                      height: 1,
                                      indent: 14,
                                      endIndent: 14,
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.10,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingRescheduleSheet extends StatefulWidget {
  const _BookingRescheduleSheet({required this.booking});
  final Booking booking;

  @override
  State<_BookingRescheduleSheet> createState() =>
      _BookingRescheduleSheetState();
}

class _BookingRescheduleSheetState extends State<_BookingRescheduleSheet> {
  late DateTime _date = widget.booking.bookingDate;
  late String _time = widget.booking.bookingTime;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ubah Jadwal',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _time,
            items: [
              for (final t in BookingRules.openSlots)
                DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: _loading
                ? null
                : (v) =>
                      setState(() => _time = v ?? BookingRules.openSlots.first),
            decoration: const InputDecoration(labelText: 'Slot Jam'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading
                ? null
                : () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      initialDate: _date,
                      selectableDayPredicate: (d) =>
                          d.weekday != DateTime.friday,
                    );
                    if (picked == null) return;
                    setState(() => _date = picked);
                  },
            icon: const Icon(Icons.date_range_rounded),
            label: Text('Tanggal: ${_fmtDate(_date)}'),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _loading
                ? null
                : () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _loading = true);
                    try {
                      await context.read<AppState>().rescheduleBookingCustomer(
                        bookingId: widget.booking.id,
                        newDate: _date,
                        newTime: _time,
                      );
                      if (!mounted) {
                        return;
                      }
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Jadwal diubah')),
                      );
                    } catch (e) {
                      if (!mounted) {
                        return;
                      }
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _loading = false);
                      }
                    }
                  },
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.time, required this.remaining});
  final String time;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final full = remaining <= 0;
    final color = full ? scheme.error : scheme.primary;
    final label = full ? 'Penuh' : 'Sisa $remaining';
    return Row(
      children: [
        Expanded(
          child: Text(
            time,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomerInvoices extends StatelessWidget {
  const _CustomerInvoices();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final invoices = state.listInvoices();
    final unpaid = invoices
        .where((s) => s.computedPaymentStatus() == PaymentStatus.unpaid)
        .length;
    final pending = invoices
        .where((s) => s.computedPaymentStatus() == PaymentStatus.pending)
        .length;
    final paid = invoices
        .where((s) => s.computedPaymentStatus() == PaymentStatus.paid)
        .length;
    final rejected = invoices
        .where((s) => s.computedPaymentStatus() == PaymentStatus.rejected)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Ringkasan Pembayaran'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Unpaid',
                value: '$unpaid',
                icon: Icons.payments_outlined,
                color: scheme.primary,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Pending',
                value: '$pending',
                icon: Icons.hourglass_top_rounded,
                color: scheme.tertiary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Paid',
                value: '$paid',
                icon: Icons.verified_rounded,
                color: Colors.green,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Rejected',
                value: '$rejected',
                icon: Icons.block_rounded,
                color: scheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _SectionHeader(title: 'Invoice Terbaru'),
        const SizedBox(height: 10),
        Card(
          child: invoices.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum ada invoice.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < invoices.length; i++)
                      Column(
                        children: [
                          _ListRow(
                            title:
                                '${invoices[i].invoice.id.toUpperCase()} • Rp ${invoices[i].invoice.total.toStringAsFixed(0)}',
                            subtitle:
                                'Status: ${invoices[i].invoice.status.label}',
                            icon: Icons.receipt_long_rounded,
                            trailing: _StatusChip(
                              label: invoices[i]
                                  .computedPaymentStatus()
                                  .name
                                  .toUpperCase(),
                              color: _paymentColor(
                                context,
                                invoices[i].computedPaymentStatus(),
                              ),
                            ),
                            onTap: () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => _InvoiceDetailSheet(
                                  summary: invoices[i],
                                  mode: _InvoiceSheetMode.customer,
                                ),
                              );
                            },
                          ),
                          if (i != invoices.length - 1)
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

Color _paymentColor(BuildContext context, PaymentStatus s) {
  final scheme = Theme.of(context).colorScheme;
  return switch (s) {
    PaymentStatus.unpaid => scheme.primary,
    PaymentStatus.pending => scheme.tertiary,
    PaymentStatus.paid => Colors.green,
    PaymentStatus.rejected => scheme.error,
  };
}

String _friendlyError(Object e) {
  final s = e.toString();
  if (s.contains('already_checked_in')) {
    return 'Anda sudah absen masuk hari ini.';
  }
  if (s.contains('already_checked_out')) {
    return 'Anda sudah absen pulang hari ini.';
  }
  if (s.contains('not_checked_in')) {
    return 'Silakan absen masuk dulu.';
  }
  if (s.contains('finish_break_first')) {
    return 'Selesaikan istirahat dulu sebelum absen pulang.';
  }
  if (s.contains('already_on_break')) {
    return 'Anda sudah mulai istirahat.';
  }
  if (s.contains('break_not_started')) {
    return 'Istirahat belum dimulai.';
  }
  if (s.contains('break_already_used') || s.contains('break_already_ended')) {
    return 'Istirahat hari ini sudah selesai.';
  }
  if (s.contains('upgrade_time_only_0800')) {
    return 'Upgrade mesin hanya bisa booking di jam 08:00.';
  }
  if (s.contains('upgrade_slot_full')) {
    return 'Slot upgrade mesin hari itu sudah penuh (maksimal 1 pekerjaan).';
  }
  if (s.contains('wa_profile_column_missing')) {
    return 'Kolom WhatsApp belum ada di database. Tambahkan kolom whatsapp di tabel profiles.';
  }
  if (s.contains('wa_profiles_update_forbidden')) {
    return 'Nomor WhatsApp belum bisa disimpan ke database (RLS). Tambahkan policy UPDATE profiles untuk user sendiri.';
  }
  if (s.contains('wa_profiles_select_forbidden')) {
    return 'Admin/kasir tidak bisa membaca nomor WhatsApp pelanggan (RLS). Tambahkan policy SELECT profiles untuk staff/admin.';
  }
  if (s.contains('wa_jobs_select_forbidden')) {
    return 'Admin/kasir tidak bisa membaca data job (RLS). Pastikan staff/admin boleh SELECT tabel jobs.';
  }
  if (s.contains('wa_save_failed')) {
    return 'Gagal menyimpan nomor WhatsApp.';
  }
  if (s.contains('invoice_items_empty')) {
    return 'Tambahkan item jasa/part dulu.';
  }
  if (s.contains('invoice_total_invalid')) {
    return 'Total invoice masih 0. Isi harga jasa/part dulu.';
  }
  if (s.contains('invoice_belum_final')) {
    return 'Invoice belum final. Silakan finalkan dulu.';
  }
  if (s.contains('requested_payment_method')) {
    return 'Kolom metode pembayaran invoice belum ada di database. Jalankan SQL setup pembayaran terbaru.';
  }
  if (s.contains('payment_accounts')) {
    return 'Pengaturan rekening transfer belum siap di database (payment_accounts). Jalankan SQL setup pembayaran.';
  }
  if (s.contains('payment_proofs') || s.contains('storage')) {
    return 'Penyimpanan bukti transfer belum siap (bucket payment_proofs). Jalankan SQL setup pembayaran.';
  }
  if (s.contains('row-level security policy') && s.contains('payments')) {
    return 'Tabel pembayaran masih ditolak oleh RLS. Tambahkan policy INSERT/SELECT/UPDATE untuk tabel payments.';
  }
  if (s.contains('proof_path') ||
      s.contains('proof_mime') ||
      s.contains('cash_received') ||
      s.contains('cash_change') ||
      s.contains('account_id')) {
    return 'Kolom pembayaran belum lengkap di database. Jalankan SQL setup pembayaran.';
  }
  if (s.contains('stok_tidak_cukup')) {
    return 'Stok tidak cukup untuk finalisasi invoice.';
  }
  if (s.contains('forbidden')) {
    return 'Akses ditolak.';
  }
  return s;
}

enum _InvoiceSheetMode { customer, cashier, admin }

class _InvoiceDetailSheet extends StatefulWidget {
  const _InvoiceDetailSheet({required this.summary, required this.mode});

  final InvoiceSummary summary;
  final _InvoiceSheetMode mode;

  @override
  State<_InvoiceDetailSheet> createState() => _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends State<_InvoiceDetailSheet> {
  final _transferRefController = TextEditingController();
  final _cashReceivedController = TextEditingController();
  bool _loading = false;
  bool _sendingWa = false;
  Uint8List? _transferProofBytes;
  String? _transferProofName;
  String? _transferProofMime;

  @override
  void dispose() {
    _transferRefController.dispose();
    _cashReceivedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = context.watch<AppState>();
    final summary = widget.summary;
    final jobs = appState.listJobs();
    final bookings = appState.listBookings();
    final payStatus = summary.computedPaymentStatus();
    Job? invoiceJob;
    for (final j in jobs) {
      if (j.id == summary.invoice.jobId) {
        invoiceJob = j;
        break;
      }
    }
    Booking? invoiceBooking;
    final bookingId = invoiceJob?.bookingId;
    if (bookingId != null && bookingId.isNotEmpty) {
      for (final b in bookings) {
        if (b.id == bookingId) {
          invoiceBooking = b;
          break;
        }
      }
    }
    final isUpgradeInvoice = invoiceBooking?.type == BookingType.modif;
    final upgradePayload = invoiceBooking?.modifPayload;
    final serviceItems = summary.items
        .where((item) => item.type == InvoiceItemType.service)
        .toList();
    final partItems = summary.items
        .where((item) => item.type == InvoiceItemType.part)
        .toList();
    final upgradeServiceTotal = serviceItems.fold<num>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
    final upgradePartsTotal = partItems.fold<num>(
      0,
      (sum, item) => sum + item.lineTotal,
    );

    final isCustomer = widget.mode == _InvoiceSheetMode.customer;
    final isAdmin = widget.mode == _InvoiceSheetMode.admin;
    final isCashier = widget.mode == _InvoiceSheetMode.cashier;
    final isStaff = isCashier || isAdmin;
    final isDraft = summary.invoice.status == InvoiceStatus.draft;
    final requestedMethod = summary.invoice.requestedPaymentMethod;

    final canSubmitTransfer =
        isCustomer &&
        requestedMethod == PaymentMethod.transfer &&
        summary.items.isNotEmpty &&
        summary.invoice.total > 0 &&
        payStatus != PaymentStatus.paid;
    final canAddService = isStaff && isDraft;
    final canChooseMethod =
        isAdmin && summary.items.isNotEmpty && summary.invoice.total > 0;
    final canVerify =
        isCashier &&
        summary.payments.any((p) => p.status == PaymentStatus.pending);
    final canPayCash =
        isCashier &&
        payStatus != PaymentStatus.paid &&
        requestedMethod != PaymentMethod.transfer;
    final canFinalizeInvoice = isAdmin && isDraft;
    final canExportPdf =
        summary.items.isNotEmpty &&
        (isStaff ||
            (isCustomer &&
                summary.invoice.status == InvoiceStatus.finalStatus));

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              summary.invoice.id.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusChip(
                  label: summary.invoice.status.label,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: payStatus.name.toUpperCase(),
                  color: _paymentColor(context, payStatus),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _kv(context, 'Subtotal', summary.invoice.subtotal),
                    _kv(context, 'Diskon', summary.invoice.discount),
                    _kv(context, 'Total', summary.invoice.total, strong: true),
                  ],
                ),
              ),
            ),
            if (isUpgradeInvoice && summary.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionHeader(title: 'Ringkasan Upgrade'),
                      const SizedBox(height: 8),
                      if (upgradePayload != null &&
                          (upgradePayload['target_cc'] as num?) != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Target: ${(upgradePayload['target_cc'] as num).toStringAsFixed(0)}cc',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.72,
                                  ),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Jasa Upgrade',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            _fmtRp(upgradeServiceTotal),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total Part',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            _fmtRp(upgradePartsTotal),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        color: scheme.onSurface.withValues(alpha: 0.10),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total Upgrade',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Text(
                            _fmtRp(summary.invoice.total),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (canExportPdf) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final bytes = await buildInvoicePdfBytes(summary: summary);
                    if (Platform.isAndroid) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Untuk cetak di Android, gunakan Share PDF lalu pilih menu Print.',
                          ),
                        ),
                      );
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename: 'invoice_${summary.invoice.id}.pdf',
                      );
                      return;
                    }
                    await Printing.layoutPdf(onLayout: (_) async => bytes);
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(_friendlyError(e))),
                    );
                  }
                },
                icon: const Icon(Icons.print_rounded),
                label: const Text('Cetak Invoice'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final bytes = await buildInvoicePdfBytes(summary: summary);
                    await Printing.sharePdf(
                      bytes: bytes,
                      filename: 'invoice_${summary.invoice.id}.pdf',
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(_friendlyError(e))),
                    );
                  }
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text('Kirim PDF'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _sendingWa
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _sendingWa = true);
                        try {
                          final state = context.read<AppState>();
                          final wa = isCustomer
                              ? state.whatsappNumber
                              : await state.resolveWhatsappForJobCustomer(
                                  jobId: summary.invoice.jobId,
                                );
                          if (wa == null || wa.trim().isEmpty) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  isCustomer
                                      ? 'Nomor WhatsApp Anda belum diisi di Profil.'
                                      : 'Nomor WhatsApp pelanggan tidak terbaca dari database.',
                                ),
                              ),
                            );
                            return;
                          }
                          final msg = [
                            'Halo, berikut invoice dari Gendut Garage.',
                            'ID: ${summary.invoice.id}',
                            'Total: ${_fmtRp(summary.invoice.total)}',
                            'Status: ${summary.invoice.status.label} / ${payStatus.name.toUpperCase()}',
                            'Setelah chat terbuka, lanjutkan dengan tombol "Kirim PDF".',
                          ].join('\n');
                          if (!context.mounted) return;
                          await _openWhatsappChat(
                            context: context,
                            normalizedNumber: wa,
                            message: msg,
                          );
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Chat WhatsApp dibuka. Lanjutkan dengan tombol "Kirim PDF".',
                              ),
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(_friendlyError(e))),
                          );
                        } finally {
                          if (mounted) setState(() => _sendingWa = false);
                        }
                      },
                icon: const Icon(Icons.chat_rounded),
                label: const Text('Chat WhatsApp'),
              ),
            ],
            const SizedBox(height: 12),
            const _SectionHeader(title: 'Item'),
            const SizedBox(height: 10),
            Card(
              child: summary.items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Item masih kosong. Tambahkan minimal 1 jasa/part.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < summary.items.length; i++)
                          Column(
                            children: [
                              _ListRow(
                                title: summary.items[i].description,
                                subtitle:
                                    'Qty ${summary.items[i].qty} • Rp ${summary.items[i].unitPrice.toStringAsFixed(0)}',
                                icon:
                                    summary.items[i].type ==
                                        InvoiceItemType.part
                                    ? Icons.inventory_2_rounded
                                    : Icons.build_rounded,
                                trailing: Text(
                                  'Rp ${summary.items[i].lineTotal.toStringAsFixed(0)}',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ),
                              if (i != summary.items.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 14,
                                  endIndent: 14,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.10,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
            ),
            if (canAddService) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final desc = TextEditingController();
                  final qty = TextEditingController(text: '1');
                  final price = TextEditingController(text: '0');
                  final messenger = ScaffoldMessenger.of(context);
                  final appState = context.read<AppState>();
                  final navigator = Navigator.of(context);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: const Text('Tambah Jasa'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: desc,
                              decoration: const InputDecoration(
                                labelText: 'Deskripsi',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: qty,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: price,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Harga',
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Tambah'),
                          ),
                        ],
                      );
                    },
                  );
                  if (!context.mounted) {
                    return;
                  }
                  if (ok != true) return;
                  final d = desc.text.trim();
                  final q = int.tryParse(qty.text.trim()) ?? 0;
                  final p = num.tryParse(price.text.trim()) ?? 0;
                  if (d.isEmpty || q <= 0) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Input tidak valid')),
                    );
                    return;
                  }
                  try {
                    await appState.addServiceItem(
                      invoiceId: summary.invoice.id,
                      description: d,
                      qty: q,
                      unitPrice: p,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Jasa ditambahkan')),
                    );
                    navigator.pop();
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(_friendlyError(e))),
                    );
                  }
                },
                icon: const Icon(Icons.playlist_add_rounded),
                label: const Text('Tambah Jasa'),
              ),
            ],
            if (canChooseMethod) ...[
              const SizedBox(height: 12),
              const _SectionHeader(title: 'Pilih Metode Pembayaran'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _loading
                          ? null
                          : requestedMethod == PaymentMethod.cash
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              setState(() => _loading = true);
                              try {
                                await appState.setInvoiceRequestedPaymentMethod(
                                  invoiceId: summary.invoice.id,
                                  method: PaymentMethod.cash,
                                );
                                if (!context.mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Metode pembayaran diset ke tunai.',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(_friendlyError(e))),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _loading = false);
                                }
                              }
                            },
                      icon: const Icon(Icons.payments_rounded),
                      label: const Text('Tunai'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : requestedMethod == PaymentMethod.transfer
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              setState(() => _loading = true);
                              try {
                                await appState.setInvoiceRequestedPaymentMethod(
                                  invoiceId: summary.invoice.id,
                                  method: PaymentMethod.transfer,
                                );
                                if (!context.mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Metode pembayaran diset ke transfer.',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(_friendlyError(e))),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _loading = false);
                                }
                              }
                            },
                      icon: const Icon(Icons.account_balance_rounded),
                      label: const Text('Transfer'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const _SectionHeader(title: 'Pembayaran'),
            const SizedBox(height: 10),
            Card(
              child: summary.payments.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Belum ada pembayaran.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < summary.payments.length; i++)
                          Column(
                            children: [
                              _ListRow(
                                title: summary.payments[i].method.name
                                    .toUpperCase(),
                                subtitle: summary.payments[i].status.name
                                    .toUpperCase(),
                                icon:
                                    summary.payments[i].method ==
                                        PaymentMethod.transfer
                                    ? Icons.account_balance_rounded
                                    : Icons.payments_rounded,
                                trailing: Text(
                                  'Rp ${summary.payments[i].amount.toStringAsFixed(0)}',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ),
                              if (i != summary.payments.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 14,
                                  endIndent: 14,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.10,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
            ),
            if (isCustomer && requestedMethod == PaymentMethod.cash) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Metode pembayaran dipilih tunai. Silakan lakukan pembayaran langsung ke kasir.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
            if (isCustomer && payStatus == PaymentStatus.rejected) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Bukti pembayaran ditolak. Silakan upload ulang bukti transfer yang sesuai dengan total biaya.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
            if (canSubmitTransfer) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final acc = appState.primaryPaymentAccount;
                  if (acc == null ||
                      acc.accountName.trim().isEmpty ||
                      acc.accountNumber.trim().isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Rekening tujuan transfer belum diset di database. Hubungi admin.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    );
                  }
                  final bankLine = <String>[
                    acc.accountName.trim(),
                    if (acc.bankName != null && acc.bankName!.trim().isNotEmpty)
                      acc.bankName!.trim(),
                  ];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Transfer ke Rekening',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bankLine.join(' • '),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  acc.accountNumber,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: acc.accountNumber),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Nomor rekening disalin'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded),
                                label: const Text('Salin'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Jumlah transfer: ${_fmtRp(summary.invoice.total)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                final res = await FilePicker.platform.pickFiles(
                                  withData: true,
                                  type: FileType.custom,
                                  allowedExtensions: const [
                                    'jpg',
                                    'jpeg',
                                    'png',
                                  ],
                                );
                                if (res == null || res.files.isEmpty) return;
                                final f = res.files.first;
                                final bytes = f.bytes;
                                if (bytes == null || bytes.isEmpty) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Gagal membaca file. Coba pilih file lain.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final name = (f.name).trim();
                                final ext = name.contains('.')
                                    ? name.split('.').last.toLowerCase()
                                    : '';
                                final mime = switch (ext) {
                                  'png' => 'image/png',
                                  'jpg' => 'image/jpeg',
                                  'jpeg' => 'image/jpeg',
                                  _ => 'application/octet-stream',
                                };
                                setState(() {
                                  _transferProofBytes = Uint8List.fromList(
                                    bytes,
                                  );
                                  _transferProofName = name.isEmpty
                                      ? 'bukti_transfer'
                                      : name;
                                  _transferProofMime = mime;
                                });
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(_friendlyError(e))),
                                );
                              }
                            },
                      icon: const Icon(Icons.attach_file_rounded),
                      label: Text(
                        _transferProofName == null
                            ? 'Lampirkan Bukti'
                            : 'Ganti Bukti',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_transferProofName != null)
                    OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() {
                                _transferProofBytes = null;
                                _transferProofName = null;
                                _transferProofMime = null;
                              });
                            },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Hapus'),
                    ),
                ],
              ),
              if (_transferProofName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Bukti: $_transferProofName',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              TextField(
                controller: _transferRefController,
                decoration: const InputDecoration(
                  labelText: 'Catatan transfer (opsional)',
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _loading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        final acc = appState.primaryPaymentAccount;
                        if (acc == null || acc.id.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Rekening tujuan belum diset di database.',
                              ),
                            ),
                          );
                          return;
                        }
                        final proofBytes = _transferProofBytes;
                        final proofName = _transferProofName;
                        final proofMime = _transferProofMime;
                        if (proofBytes == null ||
                            proofName == null ||
                            proofMime == null) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Lampirkan bukti transfer terlebih dulu.',
                              ),
                            ),
                          );
                          return;
                        }
                        final ref = _transferRefController.text.trim();
                        setState(() => _loading = true);
                        try {
                          await appState.submitTransferWithProof(
                            invoiceId: summary.invoice.id,
                            amount: summary.invoice.total,
                            transferRef: ref.isEmpty ? 'Transfer' : ref,
                            proofBytes: proofBytes,
                            proofFilename: proofName,
                            proofMime: proofMime,
                            accountId: acc.id,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Bukti transfer terkirim. Menunggu verifikasi kasir/admin.',
                              ),
                            ),
                          );
                          navigator.pop();
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(_friendlyError(e))),
                          );
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                icon: const Icon(Icons.upload_rounded),
                label: const Text('Kirim Bukti Transfer'),
              ),
            ],
            if (canPayCash) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _cashReceivedController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Uang diterima (opsional)',
                  helperText: 'Kosongkan jika uang pas.',
                  suffixText: 'Rp',
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _loading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        setState(() => _loading = true);
                        try {
                          final current = await appState.recomputeInvoiceTotals(
                            invoiceId: summary.invoice.id,
                          );
                          if (current.items.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Tambahkan item jasa/part dulu.'),
                              ),
                            );
                            return;
                          }
                          if (current.invoice.total <= 0) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Total invoice masih 0. Isi harga dulu.',
                                ),
                              ),
                            );
                            return;
                          }
                          num? received;
                          final raw = _cashReceivedController.text;
                          final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
                          if (digits.isNotEmpty) {
                            received = num.tryParse(digits);
                          }
                          await appState.payCash(
                            invoiceId: summary.invoice.id,
                            amount: current.invoice.total,
                            cashReceived: received,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Pembayaran tunai: paid'),
                            ),
                          );
                          navigator.pop();
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(_friendlyError(e))),
                          );
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                icon: const Icon(Icons.payments_rounded),
                label: const Text('Bayar Tunai'),
              ),
            ],
            if (canFinalizeInvoice) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final appState = context.read<AppState>();
                        final navigator = Navigator.of(context);
                        setState(() => _loading = true);
                        try {
                          final current = await appState.recomputeInvoiceTotals(
                            invoiceId: summary.invoice.id,
                          );
                          if (current.items.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Tambahkan item jasa/part dulu.'),
                              ),
                            );
                            return;
                          }
                          if (current.invoice.total <= 0) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Total invoice masih 0. Isi harga dulu.',
                                ),
                              ),
                            );
                            return;
                          }
                          await appState.finalizeInvoice(
                            invoiceId: summary.invoice.id,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Invoice finalized')),
                          );
                          navigator.pop();
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(_friendlyError(e))),
                          );
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Finalkan (Stok Keluar)'),
              ),
            ],
            if (canVerify) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final pendingPay = summary.payments.firstWhere(
                    (p) => p.status == PaymentStatus.pending,
                  );
                  final acc = appState.primaryPaymentAccount;
                  final proofPath = pendingPay.proofPath?.trim() ?? '';
                  final hasProof = proofPath.isNotEmpty;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Transfer Pending',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Jumlah: ${_fmtRp(pendingPay.amount)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if ((pendingPay.transferRef ?? '').trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Catatan: ${pendingPay.transferRef}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          if (acc != null &&
                              acc.accountName.trim().isNotEmpty &&
                              acc.accountNumber.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Rekening tujuan: ${[acc.accountName, if ((acc.bankName ?? '').trim().isNotEmpty) acc.bankName, acc.accountNumber].join(' • ')}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: !hasProof
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    try {
                                      final url = appState.paymentProofUrl(
                                        proofPath: proofPath,
                                      );
                                      await launchUrl(
                                        Uri.parse(url),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(_friendlyError(e)),
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.image_rounded),
                            label: Text(
                              hasProof
                                  ? 'Lihat Bukti Transfer'
                                  : 'Bukti kosong',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        final pendingPay = summary.payments.firstWhere(
                          (p) => p.status == PaymentStatus.pending,
                        );
                        try {
                          await appState.verifyTransfer(
                            paymentId: pendingPay.id,
                            approve: true,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Transfer approved')),
                          );
                          navigator.pop();
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(_friendlyError(e))),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Terima'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final appState = context.read<AppState>();
                        final navigator = Navigator.of(context);
                        final pendingPay = summary.payments.firstWhere(
                          (p) => p.status == PaymentStatus.pending,
                        );
                        try {
                          await appState.verifyTransfer(
                            paymentId: pendingPay.id,
                            approve: false,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Transfer rejected')),
                          );
                          navigator.pop();
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(_friendlyError(e))),
                          );
                        }
                      },
                      icon: const Icon(Icons.cancel_rounded),
                      label: const Text('Tolak'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(
    BuildContext context,
    String label,
    num value, {
    bool strong = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            'Rp ${value.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerProfile extends StatelessWidget {
  const _CustomerProfile();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final scheme = Theme.of(context).colorScheme;
    final vehicles = state.listVehicles();
    final jobs = state.listJobs();
    final invoices = state.listInvoices();

    final customerId = profile?.userId ?? '';
    final reward = RewardEngine.buildProgressFromServiceHistory(
      customerId: customerId,
      jobs: jobs,
      invoices: invoices,
      gmapsReviewed: state.gmapsReviewed,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Akun'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: scheme.primary.withValues(alpha: 0.14),
                  ),
                  child: Icon(Icons.person_rounded, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.fullName.isNotEmpty == true
                            ? profile!.fullName
                            : 'Pelanggan',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profile?.email.isNotEmpty == true
                            ? profile!.email
                            : '-',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.70),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Reward'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${reward.tier.label} • ${reward.points} pts',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (reward.nextTier != null)
                      Text(
                        'Next: ${reward.nextTier!.label}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.70),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: reward.progressToNext.clamp(0, 1),
                    minHeight: 10,
                    backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(
                      scheme.primary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (reward.badges.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final b in reward.badges)
                        Chip(
                          label: Text(
                            b,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  )
                else
                  Text(
                    'Kumpulkan poin dari riwayat servis.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    final url = GGSupabaseConfig.gmapsReviewUrl.trim();
                    if (url.isEmpty) {
                      _toast(
                        context,
                        'GMAPS_REVIEW_URL belum diset di build config.',
                      );
                      return;
                    }
                    final uri = Uri.tryParse(url);
                    if (uri == null) {
                      _toast(context, 'Link Google Maps tidak valid.');
                      return;
                    }
                    final ok = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!ok && context.mounted) {
                      _toast(context, 'Gagal membuka Google Maps.');
                    }
                  },
                  icon: const Icon(Icons.star_rate_rounded),
                  label: const Text('Review di Google Maps'),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: state.gmapsReviewed,
                  onChanged: (v) async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await context.read<AppState>().setGmapsReviewed(
                        reviewed: v ?? false,
                      );
                      if (!context.mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Status review disimpan')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  title: const Text(
                    'Saya sudah review di Google Maps',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('Bonus poin reward'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Kendaraan'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < vehicles.length; i++)
                Column(
                  children: [
                    _ListRow(
                      title: vehicles[i].plateNumber,
                      subtitle: '${vehicles[i].brand} • ${vehicles[i].model}',
                      icon: Icons.directions_bike_rounded,
                      onTap: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) =>
                              _VehicleUpsertSheet(vehicleId: vehicles[i].id),
                        );
                      },
                    ),
                    if (i != vehicles.length - 1)
                      Divider(
                        height: 1,
                        indent: 14,
                        endIndent: 14,
                        color: scheme.onSurface.withValues(alpha: 0.10),
                      ),
                  ],
                ),
              if (vehicles.isNotEmpty)
                Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: scheme.onSurface.withValues(alpha: 0.10),
                ),
              _ListRow(
                title: 'Tambah Kendaraan',
                subtitle: 'Plat + merk + tipe motor',
                icon: Icons.add_rounded,
                onTap: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const _VehicleUpsertSheet(vehicleId: null),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Pengaturan'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _ListRow(
                title: 'WhatsApp',
                subtitle:
                    'Nomor: ${_displayWhatsapp(context.watch<AppState>().whatsappNumber)}',
                icon: Icons.chat_rounded,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  await _showWhatsappEditor(context);
                },
              ),
              Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: scheme.onSurface.withValues(alpha: 0.10),
              ),
              _ListRow(
                title: 'Tema',
                subtitle:
                    'Tema: ${_themeModeLabel(context.watch<AppState>().themeMode)}',
                icon: Icons.brightness_6_rounded,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  await _showThemePicker(context);
                },
              ),
              Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: scheme.onSurface.withValues(alpha: 0.10),
              ),
              _ListRow(
                title: 'Logout',
                subtitle: 'Keluar dari akun ini',
                icon: Icons.logout_rounded,
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.error,
                ),
                onTap: () => context.read<AppState>().signOut(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VehicleUpsertSheet extends StatefulWidget {
  const _VehicleUpsertSheet({required this.vehicleId});
  final String? vehicleId;

  @override
  State<_VehicleUpsertSheet> createState() => _VehicleUpsertSheetState();
}

class _VehicleUpsertSheetState extends State<_VehicleUpsertSheet> {
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AppState>();
    final vehicles = state.listVehicles();
    final v = widget.vehicleId == null
        ? null
        : (() {
            for (final item in vehicles) {
              if (item.id == widget.vehicleId) {
                return item;
              }
            }
            return null;
          })();
    if (v != null && _plateController.text.isEmpty) {
      _plateController.text = v.plateNumber;
      _brandController.text = v.brand;
      _modelController.text = v.model;
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.vehicleId == null ? 'Tambah Kendaraan' : 'Edit Kendaraan',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _plateController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Plat'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _brandController,
            decoration: const InputDecoration(labelText: 'Merk'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(labelText: 'Tipe Motor'),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _loading
                ? null
                : () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final plate = _plateController.text.trim();
                    final brand = _brandController.text.trim();
                    final model = _modelController.text.trim();
                    if (plate.isEmpty || brand.isEmpty || model.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Semua field wajib diisi'),
                        ),
                      );
                      return;
                    }
                    setState(() => _loading = true);
                    try {
                      await context.read<AppState>().upsertVehicle(
                        id: widget.vehicleId,
                        plate: plate,
                        brand: brand,
                        model: model,
                      );
                      if (!mounted) {
                        return;
                      }
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Tersimpan')),
                      );
                    } catch (e) {
                      if (!mounted) {
                        return;
                      }
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _loading = false);
                      }
                    }
                  },
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
          if (widget.vehicleId != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _loading = true);
                      try {
                        await context.read<AppState>().deleteVehicle(
                          widget.vehicleId!,
                        );
                        if (!mounted) {
                          return;
                        }
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Dihapus')),
                        );
                      } catch (e) {
                        if (!mounted) {
                          return;
                        }
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _loading = false);
                        }
                      }
                    },
              child: const Text('Hapus Kendaraan'),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminBooking extends StatelessWidget {
  const _AdminBooking();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final bookings = state.listBookings();
    final pending = bookings
        .where((b) => b.status == BookingStatus.pending)
        .toList();
    final confirmed = bookings
        .where((b) => b.status == BookingStatus.confirmed)
        .toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int remaining(String time) {
      final used = bookings
          .where(
            (b) =>
                b.countsForQuota &&
                DateTime(
                      b.bookingDate.year,
                      b.bookingDate.month,
                      b.bookingDate.day,
                    ) ==
                    today &&
                b.bookingTime == time,
          )
          .length;
      return (4 - used).clamp(0, 4);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AttendanceSelfCard(),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Hari Ini'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Pending',
                value: '${pending.length}',
                icon: Icons.hourglass_top_rounded,
                color: scheme.tertiary,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Confirmed',
                value: '${confirmed.length}',
                icon: Icons.verified_rounded,
                color: Colors.green,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Upgrade Mesin',
                value:
                    '${bookings.where((b) => b.type == BookingType.modif).length}',
                icon: Icons.speed_rounded,
                color: Color(0xFF2F6BFF),
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Service',
                value:
                    '${bookings.where((b) => b.type == BookingType.service).length}',
                icon: Icons.build_rounded,
                color: Color(0xFF2F6BFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _SectionHeader(title: 'Slot (max 4)'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SlotRow(time: '08:00', remaining: remaining('08:00')),
                const SizedBox(height: 8),
                _SlotRow(time: '10:00', remaining: remaining('10:00')),
                const SizedBox(height: 8),
                _SlotRow(time: '13:00', remaining: remaining('13:00')),
                const SizedBox(height: 8),
                _SlotRow(time: '15:00', remaining: remaining('15:00')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Antrian Pending'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: pending.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Tidak ada booking pending.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ]
                : [
                    for (var i = 0; i < pending.length; i++)
                      Column(
                        children: [
                          _ListRow(
                            title:
                                '${pending[i].type.label} • ${pending[i].bookingTime} • ${pending[i].vehicleId ?? '-'}',
                            subtitle:
                                '${_fmtDate(pending[i].bookingDate)} • ${pending[i].complaint}',
                            icon: pending[i].type == BookingType.modif
                                ? Icons.speed_rounded
                                : Icons.event_note_rounded,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    try {
                                      await context
                                          .read<AppState>()
                                          .updateBookingAdmin(
                                            bookingId: pending[i].id,
                                            setStatus: BookingStatus.confirmed,
                                          );
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle_rounded),
                                  color: Colors.green,
                                  tooltip: 'Confirm',
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    try {
                                      await context
                                          .read<AppState>()
                                          .updateBookingAdmin(
                                            bookingId: pending[i].id,
                                            setStatus: BookingStatus.rejected,
                                          );
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.cancel_rounded),
                                  color: scheme.error,
                                  tooltip: 'Reject',
                                ),
                              ],
                            ),
                            onTap: () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => _BookingRescheduleAdminSheet(
                                  booking: pending[i],
                                ),
                              );
                            },
                          ),
                          if (i != pending.length - 1)
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () async {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const _BookingCheckInSheet(),
            );
          },
          icon: const Icon(Icons.login_rounded),
          label: const Text('Check-in (Buat Job)'),
        ),
      ],
    );
  }
}

class _BookingCheckInSheet extends StatelessWidget {
  const _BookingCheckInSheet();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final confirmed = state
        .listBookings()
        .where((b) => b.status == BookingStatus.confirmed)
        .toList();
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Check-in Booking',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Card(
            child: confirmed.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Tidak ada booking confirmed.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < confirmed.length; i++)
                        Column(
                          children: [
                            _ListRow(
                              title:
                                  '${confirmed[i].type.label} • ${confirmed[i].bookingTime}',
                              subtitle:
                                  '${_fmtDate(confirmed[i].bookingDate)} • ${confirmed[i].complaint}',
                              icon: confirmed[i].type == BookingType.modif
                                  ? Icons.speed_rounded
                                  : Icons.event_note_rounded,
                              trailing: IconButton(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final navigator = Navigator.of(context);
                                  try {
                                    await context
                                        .read<AppState>()
                                        .checkInBooking(
                                          bookingId: confirmed[i].id,
                                        );
                                    if (!context.mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Check-in sukses, job dibuat',
                                        ),
                                      ),
                                    );
                                    navigator.pop();
                                  } catch (e) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                },
                                icon: Icon(
                                  Icons.login_rounded,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                            if (i != confirmed.length - 1)
                              Divider(
                                height: 1,
                                indent: 14,
                                endIndent: 14,
                                color: scheme.onSurface.withValues(alpha: 0.10),
                              ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookingRescheduleAdminSheet extends StatefulWidget {
  const _BookingRescheduleAdminSheet({required this.booking});
  final Booking booking;

  @override
  State<_BookingRescheduleAdminSheet> createState() =>
      _BookingRescheduleAdminSheetState();
}

class _BookingRescheduleAdminSheetState
    extends State<_BookingRescheduleAdminSheet> {
  late DateTime _date = widget.booking.bookingDate;
  late String _time = widget.booking.bookingTime;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reschedule Booking',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _time,
            items: [
              for (final t in BookingRules.openSlots)
                DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: _loading
                ? null
                : (v) =>
                      setState(() => _time = v ?? BookingRules.openSlots.first),
            decoration: const InputDecoration(labelText: 'Slot Jam'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading
                ? null
                : () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      initialDate: _date,
                    );
                    if (picked == null) return;
                    setState(() => _date = picked);
                  },
            icon: const Icon(Icons.date_range_rounded),
            label: Text('Tanggal: ${_fmtDate(_date)}'),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _loading
                ? null
                : () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _loading = true);
                    try {
                      await context.read<AppState>().updateBookingAdmin(
                        bookingId: widget.booking.id,
                        newDate: _date,
                        newTime: _time,
                      );
                      if (!mounted) {
                        return;
                      }
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Jadwal diubah')),
                      );
                    } catch (e) {
                      if (!mounted) {
                        return;
                      }
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _loading = false);
                      }
                    }
                  },
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _AdminJobs extends StatelessWidget {
  const _AdminJobs();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final jobs = state.listJobs();
    final assigned = jobs
        .where((j) => (j.assignedMechanicId ?? '').isNotEmpty)
        .length;
    final inProgress = jobs
        .where((j) => j.status == JobStatus.inProgress)
        .length;
    final done = jobs.where((j) => j.status == JobStatus.done).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Overview'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Assigned',
                value: '$assigned',
                icon: Icons.assignment_turned_in_rounded,
                color: scheme.primary,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'In Progress',
                value: '$inProgress',
                icon: Icons.track_changes_rounded,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Done',
                value: '$done',
                icon: Icons.check_circle_rounded,
                color: Colors.green,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Butuh Assign',
                value:
                    '${jobs.where((j) => (j.assignedMechanicId ?? '').isEmpty).length}',
                icon: Icons.inventory_2_rounded,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _SectionHeader(title: 'Daftar Job'),
        const SizedBox(height: 10),
        Card(
          child: jobs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum ada job. Check-in booking untuk membuat job.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < jobs.length; i++)
                      Column(
                        children: [
                          _ListRow(
                            title: jobs[i].id.toUpperCase(),
                            subtitle: jobs[i].complaint,
                            icon: Icons.build_circle_rounded,
                            trailing: _StatusChip(
                              label: jobs[i].status.label,
                              color: _jobStatusColor(context, jobs[i].status),
                            ),
                            onTap: () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) =>
                                    _AdminJobActionsSheet(job: jobs[i]),
                              );
                            },
                          ),
                          if (i != jobs.length - 1)
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _AdminJobActionsSheet extends StatefulWidget {
  const _AdminJobActionsSheet({required this.job});

  final Job job;

  @override
  State<_AdminJobActionsSheet> createState() => _AdminJobActionsSheetState();
}

class _AdminJobActionsSheetState extends State<_AdminJobActionsSheet> {
  bool _loading = false;
  String? _selectedMechanicId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = context.watch<AppState>();
    final job = widget.job;

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              job.id.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            _StatusChip(
              label: job.status.label,
              color: _jobStatusColor(context, job.status),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Text(
                  job.complaint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.78),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder(
              future: state.listStaff(),
              builder: (context, snapshot) {
                final staff = snapshot.data ?? const <UserProfile>[];
                final mechanics = staff
                    .where((s) => s.role == AppRole.montir)
                    .toList();
                _selectedMechanicId ??=
                    job.assignedMechanicId ??
                    (mechanics.isNotEmpty ? mechanics.first.userId : null);
                return DropdownButtonFormField<String?>(
                  initialValue: _selectedMechanicId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Belum di-assign'),
                    ),
                    for (final m in mechanics)
                      DropdownMenuItem(
                        value: m.userId,
                        child: Text(m.fullName.isEmpty ? m.email : m.fullName),
                      ),
                  ],
                  onChanged: _loading
                      ? null
                      : (v) => setState(() => _selectedMechanicId = v),
                  decoration: const InputDecoration(labelText: 'Assign Montir'),
                );
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final appState = context.read<AppState>();
                      final navigator = Navigator.of(context);
                      setState(() => _loading = true);
                      try {
                        if (_selectedMechanicId != null) {
                          await appState.assignMechanic(
                            jobId: job.id,
                            mechanicUserId: _selectedMechanicId!,
                          );
                        }
                        if (!context.mounted) {
                          return;
                        }
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Job diperbarui')),
                        );
                        navigator.pop();
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Simpan'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final appState = context.read<AppState>();
                            final navigator = Navigator.of(context);
                            try {
                              await appState.updateJobStatus(
                                jobId: job.id,
                                status: JobStatus.inProgress,
                              );
                              if (!context.mounted) {
                                return;
                              }
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Status: In Progress'),
                                ),
                              );
                              navigator.pop();
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                    child: const Text('Mulai'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final appState = context.read<AppState>();
                            final navigator = Navigator.of(context);
                            try {
                              await appState.updateJobStatus(
                                jobId: job.id,
                                status: JobStatus.done,
                              );
                              if (!context.mounted) {
                                return;
                              }
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Status: Done')),
                              );
                              navigator.pop();
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                    child: const Text('Selesai'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminInvoices extends StatelessWidget {
  const _AdminInvoices();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final invoices = state.listInvoices();
    final draft = invoices
        .where((s) => s.invoice.status == InvoiceStatus.draft)
        .length;
    final finalCount = invoices
        .where((s) => s.invoice.status == InvoiceStatus.finalStatus)
        .length;
    final pendingTransfers = invoices
        .expand((s) => s.payments)
        .where(
          (p) =>
              p.method == PaymentMethod.transfer &&
              p.status == PaymentStatus.pending,
        )
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Ringkasan'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Draft',
                value: '$draft',
                icon: Icons.edit_note_rounded,
                color: scheme.primary,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Final Hari Ini',
                value: '$finalCount',
                icon: Icons.verified_rounded,
                color: Colors.green,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Transfer Pending',
                value: '$pendingTransfers',
                icon: Icons.hourglass_top_rounded,
                color: scheme.tertiary,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Void',
                value: '0',
                icon: Icons.block_rounded,
                color: scheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _SectionHeader(title: 'Invoice'),
        const SizedBox(height: 10),
        Card(
          child: invoices.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum ada invoice.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < invoices.length; i++)
                      Column(
                        children: [
                          _ListRow(
                            title:
                                '${invoices[i].invoice.id.toUpperCase()} • Rp ${invoices[i].invoice.total.toStringAsFixed(0)}',
                            subtitle:
                                'Job: ${invoices[i].invoice.jobId.toUpperCase()}',
                            icon: Icons.receipt_long_rounded,
                            trailing: _StatusChip(
                              label: invoices[i]
                                  .computedPaymentStatus()
                                  .name
                                  .toUpperCase(),
                              color: _paymentColor(
                                context,
                                invoices[i].computedPaymentStatus(),
                              ),
                            ),
                            onTap: () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => _InvoiceDetailSheet(
                                  summary: invoices[i],
                                  mode: _InvoiceSheetMode.admin,
                                ),
                              );
                            },
                          ),
                          if (i != invoices.length - 1)
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => _toast(
            context,
            'Buka detail invoice untuk finalize & verifikasi transfer.',
          ),
          icon: const Icon(Icons.done_all_rounded),
          label: const Text('Finalize Invoice'),
        ),
      ],
    );
  }
}

class _AdminStock extends StatelessWidget {
  const _AdminStock();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final parts = state.listParts();
    final activeParts = parts.where((p) => p.isActive).toList();
    final lowParts = parts.where((p) => p.isActive && p.isLowStock).toList();
    final emptyParts = parts
        .where((p) => p.isActive && p.stockOnHand <= 0)
        .toList();
    final active = parts.where((p) => p.isActive).length;
    final low = parts.where((p) => p.isActive && p.isLowStock).length;
    final empty = parts.where((p) => p.isActive && p.stockOnHand <= 0).length;

    Future<void> openSummary(String title, List<Part> items) async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _PartListSheet(title: title, parts: items),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Ringkasan Stok'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => openSummary('SKU Aktif', activeParts),
                child: _StatTile(
                  label: 'SKU Aktif',
                  value: '$active',
                  icon: Icons.qr_code_rounded,
                  color: scheme.primary,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => openSummary('Low Stock', lowParts),
                child: _StatTile(
                  label: 'Low Stock',
                  value: '$low',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => openSummary('Kosong', emptyParts),
                child: _StatTile(
                  label: 'Kosong',
                  value: '$empty',
                  icon: Icons.remove_shopping_cart_rounded,
                  color: scheme.error,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => openSummary('Total SKU', parts.toList()),
                child: _StatTile(
                  label: 'Total SKU',
                  value: '${parts.length}',
                  icon: Icons.swap_vert_rounded,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _SectionHeader(title: 'Aksi Cepat'),
        const SizedBox(height: 10),
        Row(
          children: [
            _ActionTile(
              label: 'Barang Masuk',
              icon: Icons.add_box_rounded,
              onTap: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const _StockInSheet(),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _SectionHeader(title: 'Stok Kritis'),
        const SizedBox(height: 10),
        Card(
          child:
              parts
                  .where(
                    (p) => p.isActive && (p.isLowStock || p.stockOnHand <= 0),
                  )
                  .isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Tidak ada stok kritis.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final p
                        in (parts
                            .where(
                              (p) =>
                                  p.isActive &&
                                  (p.isLowStock || p.stockOnHand <= 0),
                            )
                            .toList()
                          ..sort(
                            (a, b) => a.stockOnHand.compareTo(b.stockOnHand),
                          )))
                      Column(
                        children: [
                          _ListRow(
                            title: '${p.sku} • ${p.name}',
                            subtitle: [
                              'Sisa ${p.stockOnHand} ${p.unit}',
                              'Min ${p.minStock}',
                              'Jual ${_fmtRp(p.sellPrice)}',
                              'Beli ${_fmtRp(p.buyPrice)}',
                            ].join(' • '),
                            icon: Icons.inventory_2_rounded,
                            trailing: _StatusChip(
                              label: p.stockOnHand <= 0 ? 'Kosong' : 'Low',
                              color: p.stockOnHand <= 0
                                  ? scheme.error
                                  : Colors.orange,
                            ),
                            onTap: () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => _PartUpsertSheet(partId: p.id),
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: scheme.onSurface.withValues(alpha: 0.10),
                          ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _StockInSheet extends StatefulWidget {
  const _StockInSheet();

  @override
  State<_StockInSheet> createState() => _StockInSheetState();
}

class _StockInSheetState extends State<_StockInSheet> {
  String? _partId;
  final _qtyController = TextEditingController(text: '1');
  final _noteController = TextEditingController(text: 'Barang masuk');
  bool _loading = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final parts = state.listParts().where((p) => p.isActive).toList();
    Part? selected;
    if (_partId != null) {
      for (final p in parts) {
        if (p.id == _partId) {
          selected = p;
          break;
        }
      }
    }
    _partId ??= parts.isNotEmpty ? parts.first.id : null;
    selected ??= _partId == null
        ? null
        : (() {
            for (final p in parts) {
              if (p.id == _partId) return p;
            }
            return null;
          })();
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Barang Masuk',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionHeader(title: 'Sparepart'),
                  const SizedBox(height: 10),
                  _ListRow(
                    title: selected == null
                        ? 'Belum dipilih'
                        : '${selected.sku} • ${selected.name}',
                    subtitle: selected == null
                        ? 'Pilih part yang akan ditambah stok.'
                        : [
                            'Stok ${selected.stockOnHand} ${selected.unit}',
                            'Min ${selected.minStock}',
                            'Jual ${_fmtRp(selected.sellPrice)}',
                            'Beli ${_fmtRp(selected.buyPrice)}',
                          ].join(' • '),
                    icon: Icons.inventory_2_rounded,
                    trailing: selected == null
                        ? _StatusChip(label: 'Pilih', color: Colors.orange)
                        : _StatusChip(
                            label: selected.stockOnHand <= 0
                                ? 'Kosong'
                                : (selected.isLowStock ? 'Low' : 'Ready'),
                            color: selected.stockOnHand <= 0
                                ? Theme.of(context).colorScheme.error
                                : (selected.isLowStock
                                      ? Colors.orange
                                      : Colors.green),
                          ),
                    onTap: _loading
                        ? null
                        : () async {
                            final picked = await showModalBottomSheet<Part>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (_) => _PartPickerSheet(
                                title: 'Pilih Part dari Stok',
                                parts: parts,
                              ),
                            );
                            if (picked == null) return;
                            if (!context.mounted) return;
                            setState(() => _partId = picked.id);
                          },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading
                              ? null
                              : () async {
                                  final picked =
                                      await showModalBottomSheet<Part>(
                                        context: context,
                                        isScrollControlled: true,
                                        useSafeArea: true,
                                        builder: (_) => _PartPickerSheet(
                                          title: 'Pilih Part dari Stok',
                                          parts: parts,
                                        ),
                                      );
                                  if (picked == null) return;
                                  if (!context.mounted) return;
                                  setState(() => _partId = picked.id);
                                },
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('Pilih dari Stok'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _loading
                              ? null
                              : () async {
                                  final created =
                                      await showModalBottomSheet<Part>(
                                        context: context,
                                        isScrollControlled: true,
                                        useSafeArea: true,
                                        builder: (_) => const _PartUpsertSheet(
                                          partId: null,
                                          returnSavedPart: true,
                                        ),
                                      );
                                  if (created == null) return;
                                  if (!context.mounted) return;
                                  setState(() => _partId = created.id);
                                },
                          icon: const Icon(Icons.playlist_add_rounded),
                          label: const Text('Buat Part Baru'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Qty'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Catatan'),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _loading
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final appState = context.read<AppState>();
                    final navigator = Navigator.of(context);
                    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
                    if (_partId == null) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Part wajib dipilih')),
                      );
                      return;
                    }
                    if (qty <= 0) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Qty tidak valid')),
                      );
                      return;
                    }
                    setState(() => _loading = true);
                    try {
                      final newQty = await appState.addStockIn(
                        partId: _partId!,
                        qty: qty,
                        note: _noteController.text.trim(),
                      );
                      if (!context.mounted) {
                        return;
                      }
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Stok bertambah. Stok sekarang: $newQty',
                          ),
                        ),
                      );
                      navigator.pop();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _PartListSheet extends StatelessWidget {
  const _PartListSheet({required this.title, required this.parts});

  final String title;
  final List<Part> parts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sorted = parts.toList()..sort((a, b) => a.sku.compareTo(b.sku));
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: sorted.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada data.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 14,
                          endIndent: 14,
                          color: scheme.onSurface.withValues(alpha: 0.10),
                        ),
                        itemBuilder: (context, i) {
                          final p = sorted[i];
                          final statusLabel = p.stockOnHand <= 0
                              ? 'Kosong'
                              : (p.isLowStock ? 'Low' : 'Ready');
                          final statusColor = p.stockOnHand <= 0
                              ? scheme.error
                              : (p.isLowStock ? Colors.orange : Colors.green);
                          return _ListRow(
                            title: '${p.sku} • ${p.name}',
                            subtitle: [
                              'Stok ${p.stockOnHand} ${p.unit}',
                              'Min ${p.minStock}',
                              'Jual ${_fmtRp(p.sellPrice)}',
                              'Beli ${_fmtRp(p.buyPrice)}',
                            ].join(' • '),
                            icon: Icons.inventory_2_rounded,
                            trailing: _StatusChip(
                              label: statusLabel,
                              color: statusColor,
                            ),
                            onTap: () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => _PartUpsertSheet(partId: p.id),
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartUpsertSheet extends StatefulWidget {
  const _PartUpsertSheet({required this.partId, this.returnSavedPart = false});

  final String? partId;
  final bool returnSavedPart;

  @override
  State<_PartUpsertSheet> createState() => _PartUpsertSheetState();
}

class _PartUpsertSheetState extends State<_PartUpsertSheet> {
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController(text: 'pcs');
  final _sellController = TextEditingController(text: '0');
  final _buyController = TextEditingController(text: '0');
  final _minController = TextEditingController(text: '1');
  bool _active = true;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.partId == null) return;
    final matches = context
        .read<AppState>()
        .listParts()
        .where((x) => x.id == widget.partId)
        .toList();
    if (matches.isEmpty) return;
    final part = matches.first;
    if (_skuController.text.isEmpty) {
      _skuController.text = part.sku;
      _nameController.text = part.name;
      _unitController.text = part.unit;
      _sellController.text = part.sellPrice.toStringAsFixed(0);
      _buyController.text = part.buyPrice.toStringAsFixed(0);
      _minController.text = part.minStock.toString();
      _active = part.isActive;
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _sellController.dispose();
    _buyController.dispose();
    _minController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.partId == null ? 'Tambah Part' : 'Edit Part',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _skuController,
              decoration: const InputDecoration(labelText: 'SKU'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _unitController,
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min Stock'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga Beli'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _sellController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga Jual'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _active,
              onChanged: _loading ? null : (v) => setState(() => _active = v),
              title: const Text('Aktif'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () async {
                      final sku = _skuController.text.trim();
                      final name = _nameController.text.trim();
                      final unit = _unitController.text.trim();
                      final buy = num.tryParse(_buyController.text.trim()) ?? 0;
                      final sell =
                          num.tryParse(_sellController.text.trim()) ?? 0;
                      final min = int.tryParse(_minController.text.trim()) ?? 0;
                      if (sku.isEmpty || name.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('SKU dan Nama wajib diisi'),
                          ),
                        );
                        return;
                      }
                      setState(() => _loading = true);
                      try {
                        final appState = context.read<AppState>();
                        final navigator = Navigator.of(context);
                        final saved = await appState.upsertPart(
                          id: widget.partId,
                          sku: sku,
                          name: name,
                          unit: unit.isEmpty ? 'pcs' : unit,
                          sellPrice: sell,
                          buyPrice: buy,
                          minStock: min <= 0 ? 1 : min,
                          isActive: _active,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Tersimpan')),
                        );
                        if (widget.returnSavedPart) {
                          navigator.pop(saved);
                        } else {
                          navigator.pop();
                        }
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStaff extends StatefulWidget {
  const _AdminStaff();

  @override
  State<_AdminStaff> createState() => _AdminStaffState();
}

class _AdminStaffState extends State<_AdminStaff> {
  int _refresh = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder(
      future: state.listStaff().then((value) => (value, _refresh)),
      builder: (context, snapshot) {
        final staff = snapshot.data?.$1 ?? const <UserProfile>[];
        final total = staff.length;
        final active = staff.where((s) => s.isActive).length;
        final inactive = staff.where((s) => !s.isActive).length;
        final adminCount = staff.where((s) => s.role == AppRole.admin).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader(title: 'Staff'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Total Staff',
                    value: '$total',
                    icon: Icons.people_alt_rounded,
                    color: scheme.primary,
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    label: 'Aktif',
                    value: '$active',
                    icon: Icons.verified_user_rounded,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Nonaktif',
                    value: '$inactive',
                    icon: Icons.person_off_rounded,
                    color: scheme.error,
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    label: 'Admin',
                    value: '$adminCount',
                    icon: Icons.admin_panel_settings_rounded,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () async {
                final created = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const _CreateStaffSheet(),
                );
                if (created == true) {
                  setState(() => _refresh++);
                }
              },
              icon: const Icon(Icons.person_add_alt_rounded),
              label: Text(
                state.isMockMode ? 'Tambah Staff (Demo)' : 'Tambah Staff',
              ),
            ),
            const SizedBox(height: 12),
            const _SectionHeader(title: 'Daftar Staff'),
            const SizedBox(height: 10),
            Card(
              child: staff.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Belum ada staff.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < staff.length; i++)
                          Column(
                            children: [
                              _ListRow(
                                title:
                                    '${staff[i].role.meta.title} • ${staff[i].fullName}',
                                subtitle: staff[i].email,
                                icon: staff[i].role.meta.icon,
                                trailing: _StatusChip(
                                  label: staff[i].isActive
                                      ? 'Aktif'
                                      : 'Nonaktif',
                                  color: staff[i].isActive
                                      ? Colors.green
                                      : scheme.error,
                                ),
                              ),
                              if (i != staff.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 14,
                                  endIndent: 14,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.10,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CreateStaffSheet extends StatefulWidget {
  const _CreateStaffSheet();

  @override
  State<_CreateStaffSheet> createState() => _CreateStaffSheetState();
}

class _CreateStaffSheetState extends State<_CreateStaffSheet> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: 'staff123');
  AppRole _role = AppRole.kasir;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tambah Staff',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AppRole>(
            initialValue: _role,
            items: const [
              DropdownMenuItem(value: AppRole.kasir, child: Text('Kasir')),
              DropdownMenuItem(value: AppRole.montir, child: Text('Montir')),
              DropdownMenuItem(value: AppRole.owner, child: Text('Owner')),
              DropdownMenuItem(value: AppRole.admin, child: Text('Admin')),
            ],
            onChanged: _loading
                ? null
                : (v) => setState(() => _role = v ?? AppRole.kasir),
            decoration: const InputDecoration(labelText: 'Role'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nama'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password Sementara'),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _loading
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final name = _nameController.text.trim();
                    final email = _emailController.text.trim();
                    final pass = _passwordController.text;
                    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Semua field wajib diisi'),
                        ),
                      );
                      return;
                    }
                    setState(() => _loading = true);
                    try {
                      await context.read<AppState>().createStaff(
                        fullName: name,
                        email: email,
                        password: pass,
                        role: _role,
                      );
                      if (!mounted) {
                        return;
                      }
                      navigator.pop(true);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Staff dibuat. Login pertama wajib ganti password.',
                          ),
                          backgroundColor: scheme.primary,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) {
                        return;
                      }
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _loading = false);
                      }
                    }
                  },
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _CashierJobs extends StatefulWidget {
  const _CashierJobs();

  @override
  State<_CashierJobs> createState() => _CashierJobsState();
}

class _CashierJobsState extends State<_CashierJobs> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final jobs = state.listJobs();
    final vehicles = state.listVehicles();
    final vehicleById = {for (final v in vehicles) v.id: v};
    final invoices = state.listInvoices();
    final invoiceByJobId = {for (final s in invoices) s.invoice.jobId: s};
    final waitingInvoice = jobs
        .where(
          (j) =>
              j.status == JobStatus.done && !invoiceByJobId.containsKey(j.id),
        )
        .length;
    final waitingPay = invoices
        .where(
          (s) =>
              s.invoice.status == InvoiceStatus.finalStatus &&
              s.computedPaymentStatus() != PaymentStatus.paid,
        )
        .length;

    final q = _query.trim().toLowerCase();
    final filtered =
        (q.isEmpty
              ? jobs.toList()
              : jobs.where((j) {
                  final v = vehicleById[j.vehicleId];
                  final plate = v?.plateNumber ?? '';
                  return j.id.toLowerCase().contains(q) ||
                      plate.toLowerCase().contains(q) ||
                      j.complaint.toLowerCase().contains(q);
                }).toList())
          ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AttendanceSelfCard(),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Cari job (id / plat / keluhan)',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Ringkasan'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Menunggu Invoice',
                value: '$waitingInvoice',
                icon: Icons.receipt_long_rounded,
                color: scheme.primary,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Menunggu Bayar',
                value: '$waitingPay',
                icon: Icons.payments_rounded,
                color: scheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _SectionHeader(title: 'Job Terbaru'),
        const SizedBox(height: 10),
        Card(
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum ada job.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < filtered.length && i < 12; i++)
                      Column(
                        children: [
                          _ListRow(
                            title: () {
                              final v = vehicleById[filtered[i].vehicleId];
                              final plate = v?.plateNumber ?? '-';
                              return '${filtered[i].id.toUpperCase()} • $plate';
                            }(),
                            subtitle: filtered[i].complaint,
                            icon: Icons.assignment_rounded,
                            trailing: _StatusChip(
                              label: filtered[i].status.label,
                              color: _jobStatusColor(
                                context,
                                filtered[i].status,
                              ),
                            ),
                            onTap: () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) =>
                                    _JobDetailSheet(job: filtered[i]),
                              );
                            },
                          ),
                          if (i != (filtered.length.clamp(0, 12) - 1))
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CashierInvoices extends StatefulWidget {
  const _CashierInvoices();

  @override
  State<_CashierInvoices> createState() => _CashierInvoicesState();
}

class _CashierInvoicesState extends State<_CashierInvoices> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final vehicles = state.listVehicles();
    final vehicleById = {for (final v in vehicles) v.id: v};
    final jobs = state.listJobs();
    final jobById = {for (final j in jobs) j.id: j};
    final allInvoices = state.listInvoices().toList()
      ..sort((a, b) => b.invoice.createdAtMs.compareTo(a.invoice.createdAtMs));
    final q = _query.trim().toLowerCase();
    final invoices = q.isEmpty
        ? allInvoices
        : allInvoices.where((s) {
            final job = jobById[s.invoice.jobId];
            final plate = job == null
                ? ''
                : (vehicleById[job.vehicleId]?.plateNumber ?? '');
            return s.invoice.id.toLowerCase().contains(q) ||
                s.invoice.jobId.toLowerCase().contains(q) ||
                plate.toLowerCase().contains(q);
          }).toList();
    final draft = invoices
        .where((s) => s.invoice.status == InvoiceStatus.draft)
        .length;
    final finalCount = invoices
        .where((s) => s.invoice.status == InvoiceStatus.finalStatus)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Cari invoice (id / job / plat)',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Ringkasan'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Draft',
                value: '$draft',
                icon: Icons.edit_note_rounded,
                color: scheme.primary,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Final',
                value: '$finalCount',
                icon: Icons.verified_rounded,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _SectionHeader(title: 'Daftar Invoice'),
        const SizedBox(height: 10),
        Card(
          child: invoices.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum ada invoice.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < invoices.length && i < 14; i++)
                      Column(
                        children: [
                          _ListRow(
                            title:
                                '${invoices[i].invoice.id.toUpperCase()} • ${_fmtRp(invoices[i].invoice.total)}',
                            subtitle: () {
                              final job = jobById[invoices[i].invoice.jobId];
                              final plate = job == null
                                  ? '-'
                                  : (vehicleById[job.vehicleId]?.plateNumber ??
                                        '-');
                              final pay = invoices[i].computedPaymentStatus();
                              return '${invoices[i].invoice.status.label} • ${pay.name} • $plate';
                            }(),
                            icon: Icons.receipt_long_rounded,
                            trailing: _StatusChip(
                              label: invoices[i].invoice.status.label,
                              color:
                                  invoices[i].invoice.status ==
                                      InvoiceStatus.finalStatus
                                  ? Colors.green
                                  : scheme.primary,
                            ),
                            onTap: () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => _InvoiceDetailSheet(
                                  summary: invoices[i],
                                  mode: _InvoiceSheetMode.cashier,
                                ),
                              );
                            },
                          ),
                          if (i != (invoices.length.clamp(0, 14) - 1))
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CashierPayments extends StatelessWidget {
  const _CashierPayments();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final invoices = state.listInvoices();
    final pending = invoices.where((s) => s.hasPendingTransfer).toList()
      ..sort((a, b) => b.invoice.createdAtMs.compareTo(a.invoice.createdAtMs));
    final unpaidFinal =
        invoices
            .where(
              (s) =>
                  (s.invoice.status == InvoiceStatus.draft ||
                      s.invoice.status == InvoiceStatus.finalStatus) &&
                  s.computedPaymentStatus() != PaymentStatus.paid &&
                  !s.hasPendingTransfer,
            )
            .toList()
          ..sort(
            (a, b) => b.invoice.createdAtMs.compareTo(a.invoice.createdAtMs),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: unpaidFinal.isEmpty
                    ? null
                    : () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) =>
                              _CashierQuickPaySheet(candidates: unpaidFinal),
                        );
                      },
                icon: const Icon(Icons.payments_rounded),
                label: const Text('Bayar Tunai'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _toast(
                  context,
                  'Buka daftar transfer pending untuk verifikasi kasir.',
                ),
                icon: const Icon(Icons.info_outline_rounded),
                label: const Text('Verifikasi Transfer'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Transfer Pending'),
        const SizedBox(height: 10),
        Card(
          child: pending.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Tidak ada transfer pending.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < pending.length && i < 14; i++)
                      Column(
                        children: [
                          _ListRow(
                            title:
                                '${pending[i].invoice.id.toUpperCase()} • ${_fmtRp(pending[i].invoice.total)}',
                            subtitle: 'Menunggu verifikasi kasir/admin',
                            icon: Icons.hourglass_top_rounded,
                            trailing: _StatusChip(
                              label: 'Pending',
                              color: scheme.tertiary,
                            ),
                            onTap: () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => _InvoiceDetailSheet(
                                  summary: pending[i],
                                  mode: _InvoiceSheetMode.cashier,
                                ),
                              );
                            },
                          ),
                          if (i != (pending.length.clamp(0, 14) - 1))
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CashierQuickPaySheet extends StatefulWidget {
  const _CashierQuickPaySheet({required this.candidates});

  final List<InvoiceSummary> candidates;

  @override
  State<_CashierQuickPaySheet> createState() => _CashierQuickPaySheetState();
}

class _CashierQuickPaySheetState extends State<_CashierQuickPaySheet> {
  String? _invoiceId;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    _invoiceId ??= widget.candidates.isNotEmpty
        ? widget.candidates.first.invoice.id
        : null;
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bayar Tunai',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _invoiceId,
            items: [
              for (final s in widget.candidates)
                DropdownMenuItem(
                  value: s.invoice.id,
                  child: Text(
                    '${s.invoice.id.toUpperCase()} • ${_fmtRp(s.invoice.total)}',
                  ),
                ),
            ],
            onChanged: _loading ? null : (v) => setState(() => _invoiceId = v),
            decoration: const InputDecoration(labelText: 'Invoice'),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _loading
                ? null
                : () async {
                    final id = _invoiceId;
                    if (id == null) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Invoice wajib dipilih')),
                      );
                      return;
                    }
                    setState(() => _loading = true);
                    try {
                      final appState = context.read<AppState>();
                      InvoiceSummary current = await appState
                          .recomputeInvoiceTotals(invoiceId: id);
                      if (current.invoice.status == InvoiceStatus.draft) {
                        current = await appState.finalizeInvoice(invoiceId: id);
                      }
                      await appState.payCash(
                        invoiceId: id,
                        amount: current.invoice.total,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Pembayaran tunai tercatat'),
                        ),
                      );
                      Navigator.of(context).pop();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _loading = false);
                      }
                    }
                  },
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _CashierHistory extends StatelessWidget {
  const _CashierHistory();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final invoices = state.listInvoices();
    final now = DateTime.now();
    final todayStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;

    num cash = 0;
    num transfer = 0;
    final paidRows =
        <(int paidAtMs, String invoiceId, PaymentMethod method, num amount)>[];
    for (final s in invoices) {
      for (final p in s.payments) {
        final paidAt = p.paidAtMs;
        if (p.status != PaymentStatus.paid || paidAt == null) {
          continue;
        }
        paidRows.add((paidAt, s.invoice.id, p.method, p.amount));
        if (paidAt >= todayStart) {
          if (p.method == PaymentMethod.cash) {
            cash += p.amount;
          } else {
            transfer += p.amount;
          }
        }
      }
    }
    paidRows.sort((a, b) => b.$1.compareTo(a.$1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Rekap Hari Ini'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Tunai',
                value: _fmtRp(cash),
                icon: Icons.payments_rounded,
                color: scheme.primary,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Transfer (verified)',
                value: _fmtRp(transfer),
                icon: Icons.account_balance_rounded,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _SectionHeader(title: 'Transaksi Terbaru'),
        const SizedBox(height: 10),
        Card(
          child: paidRows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum ada transaksi paid.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < paidRows.length && i < 12; i++)
                      Column(
                        children: [
                          _ListRow(
                            title: paidRows[i].$2.toUpperCase(),
                            subtitle: () {
                              final dt = DateTime.fromMillisecondsSinceEpoch(
                                paidRows[i].$1,
                              );
                              final hh = dt.hour.toString().padLeft(2, '0');
                              final mm = dt.minute.toString().padLeft(2, '0');
                              final method =
                                  paidRows[i].$3 == PaymentMethod.cash
                                  ? 'Tunai'
                                  : 'Transfer';
                              return '$method • ${_fmtRp(paidRows[i].$4)} • $hh:$mm';
                            }(),
                            icon: Icons.receipt_long_rounded,
                            trailing: const _StatusChip(
                              label: 'Paid',
                              color: Colors.green,
                            ),
                            onTap: () async {
                              final summary = invoices.firstWhere(
                                (s) => s.invoice.id == paidRows[i].$2,
                                orElse: () => invoices.first,
                              );
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => _InvoiceDetailSheet(
                                  summary: summary,
                                  mode: _InvoiceSheetMode.cashier,
                                ),
                              );
                            },
                          ),
                          if (i != (paidRows.length.clamp(0, 12) - 1))
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MechanicJobs extends StatelessWidget {
  const _MechanicJobs();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final jobs = state.listJobs();
    final assigned = jobs.length;
    final done = jobs.where((j) => j.status == JobStatus.done).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AttendanceSelfCard(),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Hari Ini'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Assigned',
                value: '$assigned',
                icon: Icons.assignment_turned_in_rounded,
                color: scheme.primary,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Done',
                value: '$done',
                icon: Icons.check_circle_rounded,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _SectionHeader(title: 'List Job'),
        const SizedBox(height: 10),
        Card(
          child: jobs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum ada job assigned.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < jobs.length && i < 14; i++)
                      Column(
                        children: [
                          _ListRow(
                            title: jobs[i].id.toUpperCase(),
                            subtitle: jobs[i].complaint,
                            icon: jobs[i].status == JobStatus.inProgress
                                ? Icons.priority_high_rounded
                                : Icons.assignment_rounded,
                            trailing: _StatusChip(
                              label: jobs[i].status.label,
                              color: _jobStatusColor(context, jobs[i].status),
                            ),
                            onTap: () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => _JobDetailSheet(job: jobs[i]),
                              );
                            },
                          ),
                          if (i != (jobs.length.clamp(0, 14) - 1))
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Mode montir: hanya melihat aktivitas (view-only).',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _MechanicJobDetail extends StatelessWidget {
  const _MechanicJobDetail();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final jobs = state.listJobs();
    final inProgress = jobs
        .where((j) => j.status == JobStatus.inProgress)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Job Aktif'),
        const SizedBox(height: 10),
        Card(
          child: inProgress.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Tidak ada job in progress.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : _ListRow(
                  title: inProgress.first.id.toUpperCase(),
                  subtitle: inProgress.first.complaint,
                  icon: Icons.priority_high_rounded,
                  trailing: _StatusChip(
                    label: inProgress.first.status.label,
                    color: scheme.primary,
                  ),
                  onTap: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => _JobDetailSheet(job: inProgress.first),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Semua Job Saya'),
        const SizedBox(height: 10),
        Card(
          child: jobs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum ada job assigned.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < jobs.length && i < 12; i++)
                      Column(
                        children: [
                          _ListRow(
                            title: jobs[i].id.toUpperCase(),
                            subtitle: jobs[i].status.label,
                            icon: Icons.assignment_rounded,
                            trailing: _StatusChip(
                              label: jobs[i].status.label,
                              color: _jobStatusColor(context, jobs[i].status),
                            ),
                            onTap: () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => _JobDetailSheet(job: jobs[i]),
                              );
                            },
                          ),
                          if (i != (jobs.length.clamp(0, 12) - 1))
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MechanicParts extends StatefulWidget {
  const _MechanicParts();

  @override
  State<_MechanicParts> createState() => _MechanicPartsState();
}

class _MechanicPartsState extends State<_MechanicParts> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final q = _query.trim().toLowerCase();
    final parts = state.listParts().where((p) => p.isActive).toList()
      ..sort((a, b) => a.sku.compareTo(b.sku));
    final filtered = q.isEmpty
        ? parts
        : parts.where((p) {
            return p.sku.toLowerCase().contains(q) ||
                p.name.toLowerCase().contains(q);
          }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Part'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.search_rounded),
                label: const Text('Cari Part'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Cari part (SKU / nama)',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Katalog Part'),
        const SizedBox(height: 10),
        Card(
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Part tidak ditemukan.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < filtered.length && i < 16; i++)
                      Column(
                        children: [
                          _ListRow(
                            title: '${filtered[i].sku} • ${filtered[i].name}',
                            subtitle:
                                'Stok ${filtered[i].stockOnHand} ${filtered[i].unit} • Min ${filtered[i].minStock}',
                            icon: Icons.inventory_2_rounded,
                            trailing: _StatusChip(
                              label: filtered[i].stockOnHand <= 0
                                  ? 'Kosong'
                                  : (filtered[i].isLowStock ? 'Low' : 'Ready'),
                              color: filtered[i].stockOnHand <= 0
                                  ? scheme.error
                                  : (filtered[i].isLowStock
                                        ? Colors.orange
                                        : Colors.green),
                            ),
                            onTap: null,
                          ),
                          if (i != (filtered.length.clamp(0, 16) - 1))
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        Text(
          'Stok hanya berkurang saat invoice final (kasir/admin).',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _OwnerDashboard extends StatelessWidget {
  const _OwnerDashboard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final invoices = state.listInvoices();
    final jobs = state.listJobs();

    final now = DateTime.now();
    final todayStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;

    num omzetHariIni = 0;
    var transferPending = 0;
    var invoiceFinal = 0;
    for (final s in invoices) {
      if (s.invoice.status == InvoiceStatus.finalStatus) {
        invoiceFinal++;
      }
      if (s.hasPendingTransfer) {
        transferPending++;
      }
      for (final p in s.payments) {
        if (p.status == PaymentStatus.paid &&
            p.paidAtMs != null &&
            p.paidAtMs! >= todayStart) {
          omzetHariIni += p.amount;
        }
      }
    }
    final jobSelesai = jobs.where((j) => j.status == JobStatus.done).length;

    final last7 = List<int>.filled(7, 0);
    for (var d = 0; d < 7; d++) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - d));
      final start = DateTime(
        day.year,
        day.month,
        day.day,
      ).millisecondsSinceEpoch;
      final end = start + const Duration(days: 1).inMilliseconds;
      num sum = 0;
      for (final s in invoices) {
        for (final p in s.payments) {
          final paidAt = p.paidAtMs;
          if (p.status != PaymentStatus.paid || paidAt == null) {
            continue;
          }
          if (paidAt >= start && paidAt < end) {
            sum += p.amount;
          }
        }
      }
      last7[d] = (sum / 1000).round().clamp(0, 999999);
    }

    final paidInvoices = invoices.where(
      (s) => s.computedPaymentStatus() == PaymentStatus.paid,
    );
    final serviceCount = <String, int>{};
    final partCount = <String, int>{};
    for (final s in paidInvoices) {
      for (final it in s.items) {
        if (it.type == InvoiceItemType.service) {
          serviceCount[it.description] =
              (serviceCount[it.description] ?? 0) + 1;
        } else {
          partCount[it.description] = (partCount[it.description] ?? 0) + it.qty;
        }
      }
    }
    final topService = serviceCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topPart = partCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _OwnerAttendancePreview(),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Ringkasan'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Omzet Hari Ini',
                value: _fmtRp(omzetHariIni),
                icon: Icons.payments_rounded,
                color: scheme.primary,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Invoice Final',
                value: '$invoiceFinal',
                icon: Icons.receipt_long_rounded,
                color: Colors.green,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Job Selesai',
                value: '$jobSelesai',
                icon: Icons.check_circle_rounded,
                color: Colors.green,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Transfer Pending',
                value: '$transferPending',
                icon: Icons.hourglass_top_rounded,
                color: scheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _SectionHeader(title: 'Tren 7 Hari'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: _MiniBarChart(values: last7),
          ),
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Top Hari Ini'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _ListRow(
                title: topService.isEmpty
                    ? 'Belum ada transaksi'
                    : 'Jasa: ${topService.first.key}',
                subtitle: topService.isEmpty
                    ? '—'
                    : '${topService.first.value}x transaksi',
                icon: Icons.build_rounded,
                trailing: _StatusChip(label: 'Top', color: scheme.primary),
                onTap: () {},
              ),
              Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: scheme.onSurface.withValues(alpha: 0.10),
              ),
              _ListRow(
                title: topPart.isEmpty
                    ? 'Part: —'
                    : 'Part: ${topPart.first.key}',
                subtitle: topPart.isEmpty
                    ? '—'
                    : '${topPart.first.value} ${topPart.first.value == 1 ? 'pc' : 'pcs'} terjual',
                icon: Icons.inventory_2_rounded,
                trailing: _StatusChip(label: 'Top', color: scheme.primary),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.values});
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = values.isEmpty
        ? 1
        : values.reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final v in values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                height: 72 * (v / maxValue).clamp(0.08, 1.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: scheme.primary.withValues(alpha: 0.80),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OwnerReports extends StatelessWidget {
  const _OwnerReports();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final invoices = state.listInvoices();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month).millisecondsSinceEpoch;

    num omzet = 0;
    var transaksi = 0;
    num jasa = 0;
    num sparepart = 0;
    num cash = 0;
    num transfer = 0;

    for (final s in invoices) {
      for (final p in s.payments) {
        final paidAt = p.paidAtMs;
        if (p.status != PaymentStatus.paid || paidAt == null) {
          continue;
        }
        if (paidAt < monthStart) {
          continue;
        }
        omzet += p.amount;
        if (p.method == PaymentMethod.cash) {
          cash += p.amount;
        } else {
          transfer += p.amount;
        }
      }
      if (s.computedPaymentStatus() == PaymentStatus.paid) {
        if (s.invoice.createdAtMs >= monthStart) {
          transaksi++;
        }
        for (final it in s.items) {
          if (it.type == InvoiceItemType.service) {
            jasa += it.lineTotal;
          } else {
            sparepart += it.lineTotal;
          }
        }
      }
    }

    final totalKomposisi = (jasa + sparepart).clamp(1, 999999999);
    final jasaPct = (jasa / totalKomposisi).clamp(0, 1).toDouble();
    final partPct = (sparepart / totalKomposisi).clamp(0, 1).toDouble();
    final totalBayar = (cash + transfer).clamp(1, 999999999);
    final cashPct = (cash / totalBayar).clamp(0, 1).toDouble();
    final transferPct = (transfer / totalBayar).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Ringkasan Bulan Ini'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Omzet',
                value: _fmtRp(omzet),
                icon: Icons.payments_rounded,
                color: scheme.primary,
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Transaksi',
                value: '$transaksi',
                icon: Icons.receipt_long_rounded,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Komposisi'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RatioRow(label: 'Jasa', value: jasaPct),
                const SizedBox(height: 10),
                _RatioRow(label: 'Sparepart', value: partPct),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Metode Bayar (verified)'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [
                _RatioRow(label: 'Tunai', value: cashPct),
                const SizedBox(height: 10),
                _RatioRow(label: 'Transfer', value: transferPct),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _SectionHeader(title: 'Laporan'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _ListRow(
                title: 'Data Pelanggan',
                subtitle: 'Unit, servis selesai, total belanja',
                icon: Icons.people_alt_rounded,
                onTap: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const _OwnerCustomerReportSheet(),
                  );
                },
              ),
              Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: scheme.onSurface.withValues(alpha: 0.10),
              ),
              _ListRow(
                title: 'Sparepart Keluar/Masuk',
                subtitle: 'Pergerakan stok (stock_movements)',
                icon: Icons.swap_vert_rounded,
                onTap: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const _OwnerStockMovementReportSheet(),
                  );
                },
              ),
              Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: scheme.onSurface.withValues(alpha: 0.10),
              ),
              _ListRow(
                title: 'Riwayat Servis',
                subtitle: 'Prioritas, estimasi, tindakan',
                icon: Icons.history_rounded,
                onTap: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const _OwnerServiceHistoryReportSheet(),
                  );
                },
              ),
              Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: scheme.onSurface.withValues(alpha: 0.10),
              ),
              _ListRow(
                title: 'Performa Pelanggan (Reward)',
                subtitle: 'Poin, badge, ranking sederhana',
                icon: Icons.emoji_events_rounded,
                onTap: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const _OwnerCustomerPerformanceSheet(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnerCustomerReportSheet extends StatelessWidget {
  const _OwnerCustomerReportSheet();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final customers = state.customers;
    final vehicles = state.listVehicles();
    final jobs = state.listJobs();
    final invoices = state.listInvoices();

    num totalAll = 0;
    final rows = customers.map((c) {
      final vCount = vehicles.where((v) => v.customerId == c.userId).length;
      final stats = RewardEngine.computeServiceStats(
        customerId: c.userId,
        jobs: jobs,
        invoices: invoices,
      );
      totalAll += stats.totalPaid;
      final pts = RewardEngine.computePoints(
        jobsDone: stats.jobsDone,
        totalPaid: stats.totalPaid,
        gmapsReviewed: false,
        totalEtaMinutes: stats.totalEtaMinutes,
        serviceActionsDone: stats.serviceActionsDone,
        rendahDone: stats.rendahDone,
        menengahDone: stats.menengahDone,
        daruratDone: stats.daruratDone,
      );
      return (c, vCount, stats.jobsDone, stats.totalPaid, pts);
    }).toList()..sort((a, b) => (b.$4).compareTo(a.$4));

    Future<void> refresh() => context.read<AppState>().manualRefresh();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Laporan Pelanggan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Memperbarui data...')),
                    );
                    try {
                      await refresh();
                      if (!context.mounted) return;
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Data sudah diperbarui')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                ),
                Text(
                  'Total ${_fmtRp(totalAll)}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: refresh,
                child: customers.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Text(
                              'Tidak ada data pelanggan atau akses tidak tersedia.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.72,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      )
                    : Card(
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: scheme.onSurface.withValues(alpha: 0.10),
                          ),
                          itemBuilder: (context, i) {
                            final (c, vCount, done, paid, pts) = rows[i];
                            final name = c.fullName.isNotEmpty
                                ? c.fullName
                                : c.email;
                            return _ListRow(
                              title: name,
                              subtitle:
                                  'Unit $vCount • Servis done $done • Poin $pts',
                              icon: Icons.person_rounded,
                              trailing: Text(
                                _fmtRp(paid),
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              onTap: () {},
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerStockMovementReportSheet extends StatefulWidget {
  const _OwnerStockMovementReportSheet();

  @override
  State<_OwnerStockMovementReportSheet> createState() =>
      _OwnerStockMovementReportSheetState();
}

class _OwnerStockMovementReportSheetState
    extends State<_OwnerStockMovementReportSheet> {
  bool _loading = true;
  String? _error;
  List<StockMovement> _rows = const [];

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    Future<void>.microtask(() async {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      try {
        final items = await appState.fetchStockMovements(
          start: start,
          end: now,
        );
        if (!mounted) return;
        setState(() {
          _rows = items;
          _loading = false;
          _error = null;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _rows = const [];
          _loading = false;
          _error = e.toString();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = context.watch<AppState>().listParts();
    final partById = {for (final p in parts) p.id: p};
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Laporan Stok Keluar/Masuk (30 hari)',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else if (_rows.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Belum ada pergerakan stok.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Card(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: scheme.onSurface.withValues(alpha: 0.10),
                    ),
                    itemBuilder: (context, i) {
                      final m = _rows[i];
                      final part = partById[m.partId];
                      final title = part == null
                          ? m.partId
                          : '${part.sku} • ${part.name}';
                      final typeLabel = switch (m.type) {
                        StockMovementType.inMove => 'IN',
                        StockMovementType.outMove => 'OUT',
                        StockMovementType.adjust => 'ADJ',
                        StockMovementType.refund => 'RFND',
                      };
                      final typeColor = switch (m.type) {
                        StockMovementType.inMove => Colors.green,
                        StockMovementType.outMove => scheme.error,
                        StockMovementType.adjust => scheme.onSurface.withValues(
                          alpha: 0.60,
                        ),
                        StockMovementType.refund => scheme.primary,
                      };
                      return _ListRow(
                        title: '$typeLabel • $title',
                        subtitle: '${m.qty} • ${m.note}',
                        icon: switch (m.type) {
                          StockMovementType.inMove =>
                            Icons.call_received_rounded,
                          StockMovementType.outMove => Icons.call_made_rounded,
                          StockMovementType.adjust => Icons.tune_rounded,
                          StockMovementType.refund => Icons.undo_rounded,
                        },
                        trailing: _StatusChip(
                          label: typeLabel,
                          color: typeColor,
                        ),
                        onTap: () {},
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OwnerServiceHistoryReportSheet extends StatelessWidget {
  const _OwnerServiceHistoryReportSheet();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final jobs = state.listJobs().toList()
      ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    final done = jobs.where((j) => j.status == JobStatus.done).toList();
    final rows = done.isEmpty ? jobs : done;
    final limited = rows.take(60).toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Laporan Riwayat Servis',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: limited.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada job.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: limited.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 14,
                          endIndent: 14,
                          color: scheme.onSurface.withValues(alpha: 0.10),
                        ),
                        itemBuilder: (context, i) {
                          final j = limited[i];
                          final pri = j.priority?.label ?? '—';
                          final eta = j.etaMinutes == null
                              ? '—'
                              : '${j.etaMinutes}m';
                          final actions = j.serviceActions.isEmpty
                              ? '0 tindakan'
                              : '${j.serviceActions.length} tindakan';
                          return _ListRow(
                            title: j.id.toUpperCase(),
                            subtitle:
                                'Status ${j.status.label} • Prioritas $pri • ETA $eta • $actions',
                            icon: Icons.build_circle_rounded,
                            trailing: _StatusChip(
                              label: pri,
                              color: j.priority == ServicePriority.darurat
                                  ? scheme.error
                                  : (j.priority == ServicePriority.menengah
                                        ? scheme.tertiary
                                        : scheme.primary),
                            ),
                            onTap: () {},
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerCustomerPerformanceSheet extends StatelessWidget {
  const _OwnerCustomerPerformanceSheet();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final customers = state.customers;
    final vehicles = state.listVehicles();
    final jobs = state.listJobs();
    final invoices = state.listInvoices();

    final rows = customers.map((c) {
      final vCount = vehicles.where((v) => v.customerId == c.userId).length;
      final progress = RewardEngine.buildProgressFromServiceHistory(
        customerId: c.userId,
        jobs: jobs,
        invoices: invoices,
        gmapsReviewed: false,
      );
      return (
        c,
        vCount,
        progress.stats.jobsDone,
        progress.stats.totalPaid,
        progress,
      );
    }).toList()..sort((a, b) => b.$5.points.compareTo(a.$5.points));

    final limited = rows.take(40).toList();
    Future<void> refresh() => context.read<AppState>().manualRefresh();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Performa Pelanggan (Reward)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Memperbarui data...')),
                    );
                    try {
                      await refresh();
                      if (!context.mounted) return;
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Data sudah diperbarui')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: refresh,
                child: limited.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Text(
                              'Tidak ada data pelanggan atau akses tidak tersedia.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.72,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      )
                    : Card(
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: limited.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: scheme.onSurface.withValues(alpha: 0.10),
                          ),
                          itemBuilder: (context, i) {
                            final (c, vCount, done, paid, progress) =
                                limited[i];
                            final name = c.fullName.isNotEmpty
                                ? c.fullName
                                : c.email;
                            return _ListRow(
                              title:
                                  '${i + 1}. $name • ${progress.tier.label} • ${progress.points} pts',
                              subtitle:
                                  'Unit $vCount • Servis done $done • Total ${_fmtRp(paid)}',
                              icon: Icons.emoji_events_rounded,
                              trailing: _StatusChip(
                                label: progress.tier.label,
                                color: scheme.primary,
                              ),
                              onTap: () {},
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatioRow extends StatelessWidget {
  const _RatioRow({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (value * 100).round();
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 10,
              backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(
                scheme.primary.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text(
            '$pct%',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
        ),
      ],
    );
  }
}

class _OwnerStockCritical extends StatelessWidget {
  const _OwnerStockCritical();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final critical =
        state
            .listParts()
            .where((p) => p.isActive && (p.isLowStock || p.stockOnHand <= 0))
            .toList()
          ..sort((a, b) => a.stockOnHand.compareTo(b.stockOnHand));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Stok Kritis (Read-only)'),
        const SizedBox(height: 10),
        Card(
          child: critical.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Tidak ada stok kritis.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < critical.length && i < 16; i++)
                      Column(
                        children: [
                          _ListRow(
                            title: '${critical[i].sku} • ${critical[i].name}',
                            subtitle:
                                'Sisa ${critical[i].stockOnHand} ${critical[i].unit} • Min ${critical[i].minStock}',
                            icon: Icons.inventory_2_rounded,
                            trailing: _StatusChip(
                              label: critical[i].stockOnHand <= 0
                                  ? 'Kosong'
                                  : 'Low',
                              color: critical[i].stockOnHand <= 0
                                  ? scheme.error
                                  : Colors.orange,
                            ),
                            onTap: () {},
                          ),
                          if (i != (critical.length.clamp(0, 16) - 1))
                            Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _OwnerProfile extends StatelessWidget {
  const _OwnerProfile();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Owner'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: scheme.primary.withValues(alpha: 0.14),
                  ),
                  child: Icon(Icons.insights_rounded, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Owner',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Read-only dashboard & laporan',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
