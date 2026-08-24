import 'package:flutter/material.dart';

enum AppRole {
  pelanggan,
  kasir,
  montir,
  owner,
  admin,
}

class AppRoleMeta {
  const AppRoleMeta({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

extension AppRoleX on AppRole {
  AppRoleMeta get meta {
    return switch (this) {
      AppRole.pelanggan => const AppRoleMeta(
          title: 'Pelanggan',
          subtitle: 'Booking, status servis, invoice, kalkulator upgrade mesin.',
          icon: Icons.person_rounded,
        ),
      AppRole.kasir => const AppRoleMeta(
          title: 'Kasir',
          subtitle: 'Invoice, pembayaran tunai, riwayat transaksi.',
          icon: Icons.point_of_sale_rounded,
        ),
      AppRole.montir => const AppRoleMeta(
          title: 'Montir',
          subtitle: 'Job hari ini, progres kerja, catat part terpakai.',
          icon: Icons.construction_rounded,
        ),
      AppRole.owner => const AppRoleMeta(
          title: 'Owner',
          subtitle: 'Dashboard & laporan (read-only) untuk monitoring.',
          icon: Icons.insights_rounded,
        ),
      AppRole.admin => const AppRoleMeta(
          title: 'Admin',
          subtitle: 'Booking, job, invoice, stok, staff.',
          icon: Icons.admin_panel_settings_rounded,
        ),
    };
  }

  static AppRole? tryParse(String value) {
    return switch (value) {
      'pelanggan' => AppRole.pelanggan,
      'kasir' => AppRole.kasir,
      'montir' => AppRole.montir,
      'owner' => AppRole.owner,
      'admin' => AppRole.admin,
      _ => null,
    };
  }
}
