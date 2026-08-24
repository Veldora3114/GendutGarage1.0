import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gendut_garage/config/gg_supabase.dart';
import 'package:gendut_garage/models/app_role.dart';
import 'package:gendut_garage/models/attendance.dart';
import 'package:gendut_garage/models/booking.dart';
import 'package:gendut_garage/models/engine_preset.dart';
import 'package:gendut_garage/models/invoice.dart';
import 'package:gendut_garage/models/job.dart';
import 'package:gendut_garage/models/part.dart';
import 'package:gendut_garage/models/profile.dart';
import 'package:gendut_garage/models/vehicle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppState extends ChangeNotifier {
  AppState({bool enableSupabase = true}) : _enableSupabase = enableSupabase;

  final bool _enableSupabase;

  bool _initialized = false;
  bool get initialized => _initialized;

  bool get isSupabaseConfigured => GGSupabaseConfig.isConfigured;
  bool get isMockMode =>
      !_enableSupabase || const bool.fromEnvironment('FLUTTER_TEST');

  bool _initializing = false;

  String? _initError;
  String? get initError => _initError;

  UserProfile? _profile;
  UserProfile? get profile => _profile;
  bool get isLoggedIn => _profile != null;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  static const _kPrefThemeMode = 'gg_theme_mode';

  String? _whatsappNumber;
  String? get whatsappNumber => _whatsappNumber;

  ThemeMode _parseThemeMode(Object? value) {
    final v = value?.toString().toLowerCase().trim();
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> _loadLocalThemeMode() async {
    if (isMockMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kPrefThemeMode);
      final parsed = _parseThemeMode(saved);
      if (_themeMode != parsed) {
        _themeMode = parsed;
      }
    } catch (_) {}
  }

  Future<void> _saveLocalThemeMode() async {
    if (isMockMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefThemeMode, _themeMode.name);
    } catch (_) {}
  }

  String _normalizeWhatsapp(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('62')) return digits;
    if (digits.startsWith('0')) return '62${digits.substring(1)}';
    if (digits.startsWith('8')) return '62$digits';
    return digits;
  }

  String? _pickWhatsappFromProfileRow(Map<String, dynamic> row) {
    final candidates = <Object?>[
      row['whatsapp'],
      row['wa'],
      row['phone'],
      row['phone_number'],
      row['mobile'],
    ];
    for (final v in candidates) {
      final s = v?.toString().trim() ?? '';
      if (s.isEmpty) continue;
      final n = _normalizeWhatsapp(s);
      if (n.isNotEmpty) return n;
    }
    return null;
  }

  bool? _gmapsReviewed;
  bool get gmapsReviewed => _gmapsReviewed ?? false;

  Timer? _bookingAutoRefreshTimer;
  bool _bookingAutoRefreshing = false;
  Future<void>? _manualRefreshFuture;

  bool _bookingListsEqual(List<Booking> a, List<Booking> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x.id != y.id) return false;
      if (x.status != y.status) return false;
      if (x.bookingDate != y.bookingDate) return false;
      if (x.bookingTime != y.bookingTime) return false;
      if (x.complaint != y.complaint) return false;
      if (x.type != y.type) return false;
    }
    return true;
  }

  void _startBookingAutoRefresh() {
    _bookingAutoRefreshTimer?.cancel();
    _bookingAutoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_bookingAutoRefreshing) return;
      _bookingAutoRefreshing = true;
      Future<void>(() async {
        try {
          final actor = _profile;
          if (actor == null) return;
          final before = _bookings;
          await _refreshBookings();
          if (!_bookingListsEqual(before, _bookings)) {
            notifyListeners();
          }
        } catch (_) {
        } finally {
          _bookingAutoRefreshing = false;
        }
      });
    });
  }

  void _stopBookingAutoRefresh() {
    _bookingAutoRefreshTimer?.cancel();
    _bookingAutoRefreshTimer = null;
    _bookingAutoRefreshing = false;
  }

  Future<void> manualRefresh() {
    final actor = _profile;
    if (actor == null) return Future<void>.value();
    final inFlight = _manualRefreshFuture;
    if (inFlight != null) return inFlight;

    final f =
        Future<void>(() async {
          await refreshAll();
          await _loadRewardFlags();
          _startRealtimeIfNeeded();
        }).whenComplete(() {
          _manualRefreshFuture = null;
        });
    _manualRefreshFuture = f;
    return f;
  }

  List<UserProfile> _staff = const [];
  List<UserProfile> get staff => _staff;

  List<UserProfile> _customers = const [];
  List<UserProfile> get customers => _customers;

  List<Vehicle> _vehicles = const [];
  List<Vehicle> listVehicles() => _vehicles;

  List<Booking> _bookings = const [];
  List<Booking> listBookings() => _bookings;

  List<EnginePreset> _enginePresets = const [];
  List<EnginePreset> listEnginePresets() => _enginePresets;

  List<ServiceType> _serviceTypes = const [];
  List<ServiceType> listServiceTypes() => _serviceTypes;

  List<ServiceSubtype> _serviceSubtypes = const [];
  List<ServiceSubtype> listServiceSubtypes() => _serviceSubtypes;

  List<ServiceSubtypePart> _serviceSubtypeParts = const [];
  List<ServiceSubtypePart> listServiceSubtypeParts(String serviceSubtypeId) =>
      _serviceSubtypeParts
          .where((x) => x.serviceSubtypeId == serviceSubtypeId)
          .toList();
  List<ServiceSubtypePart> listAllServiceSubtypeParts() => _serviceSubtypeParts;

  String? _serviceCatalogError;
  String? get serviceCatalogError => _serviceCatalogError;

  Future<void> refreshServiceCatalog() async {
    final actor = _profile;
    if (actor == null) return;
    await _refreshServiceCatalog();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveLocalThemeMode();
    notifyListeners();
    final actor = _profile;
    if (actor == null) return;
    try {
      await _client.auth.updateUser(
        UserAttributes(data: {'theme_mode': mode.name}),
      );
    } catch (_) {}
    try {
      await _client
          .from('profiles')
          .update({'theme_mode': mode.name})
          .eq('id', actor.userId);
    } catch (_) {}
  }

  Future<void> setWhatsappNumber(String rawNumber) async {
    final normalized = _normalizeWhatsapp(rawNumber);
    _whatsappNumber = normalized.isEmpty ? null : normalized;
    notifyListeners();

    final actor = _profile;
    if (actor == null) return;

    try {
      await _client.auth.updateUser(
        UserAttributes(
          data: {
            'whatsapp': _whatsappNumber,
            'wa': _whatsappNumber,
            'phone': _whatsappNumber,
          },
        ),
      );
    } catch (_) {}

    try {
      await _client
          .from('profiles')
          .update({'whatsapp': _whatsappNumber})
          .eq('id', actor.userId);
    } catch (e) {
      if (e is PostgrestException) {
        final msg = e.message.toLowerCase();
        if (msg.contains('column') && msg.contains('whatsapp')) {
          throw Exception('wa_profile_column_missing');
        }
        if (msg.contains('permission') ||
            msg.contains('row level security') ||
            msg.contains('rls') ||
            (e.code?.toString() == '42501')) {
          throw Exception('wa_profiles_update_forbidden');
        }
      }
      throw Exception('wa_save_failed');
    }
  }

  Future<void> _syncWhatsappToProfileIfMissing() async {
    final actor = _profile;
    final normalized = _normalizeWhatsapp(_whatsappNumber ?? '');
    if (actor == null || normalized.isEmpty) return;
    try {
      final row = await _client
          .from('profiles')
          .select('whatsapp')
          .eq('id', actor.userId)
          .maybeSingle();
      final existing = _normalizeWhatsapp(row?['whatsapp']?.toString() ?? '');
      if (existing.isNotEmpty) return;
      await _client
          .from('profiles')
          .update({'whatsapp': normalized})
          .eq('id', actor.userId);
    } catch (_) {}
  }

  Future<String?> resolveWhatsappForJobCustomer({required String jobId}) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role == AppRole.pelanggan) {
      return _whatsappNumber;
    }

    String? customerId;
    String? bookingId;
    for (final j in _jobs) {
      if (j.id == jobId) {
        customerId = j.customerId;
        bookingId = j.bookingId;
        break;
      }
    }
    if (customerId == null || customerId.isEmpty) {
      try {
        final row = await _client
            .from('jobs')
            .select('customer_id, booking_id')
            .eq('id', jobId)
            .maybeSingle();
        customerId = row?['customer_id']?.toString();
        bookingId = row?['booking_id']?.toString();
      } catch (e) {
        if (e is PostgrestException) {
          throw Exception('wa_jobs_select_forbidden');
        }
        customerId = null;
      }
    }
    if (customerId == null || customerId.isEmpty) return null;

    if (bookingId != null && bookingId.isNotEmpty) {
      try {
        final row = await _client
            .from('bookings')
            .select('customer_whatsapp')
            .eq('id', bookingId)
            .maybeSingle();
        final raw = row?['customer_whatsapp']?.toString() ?? '';
        final normalized = _normalizeWhatsapp(raw);
        if (normalized.isNotEmpty) return normalized;
      } catch (_) {}
    }

    try {
      final rows = await _client
          .from('bookings')
          .select('customer_whatsapp, created_at')
          .eq('customer_id', customerId)
          .not('customer_whatsapp', 'is', null)
          .order('created_at', ascending: false)
          .limit(5);
      for (final r in (rows as List)) {
        final raw = (r as Map)['customer_whatsapp']?.toString() ?? '';
        final normalized = _normalizeWhatsapp(raw);
        if (normalized.isNotEmpty) return normalized;
      }
    } catch (_) {}

    try {
      final row = await _client
          .from('profiles')
          .select('whatsapp, wa, phone, phone_number, mobile')
          .eq('id', customerId)
          .maybeSingle();
      if (row == null) return null;
      final parsed = _pickWhatsappFromProfileRow(
        (row as Map).cast<String, dynamic>(),
      );
      return parsed;
    } catch (e) {
      if (e is PostgrestException) {
        final msg = e.message.toLowerCase();
        if (msg.contains('permission') ||
            msg.contains('row level security') ||
            msg.contains('rls') ||
            (e.code?.toString() == '42501')) {
          throw Exception('wa_profiles_select_forbidden');
        }
        if (msg.contains('column') && msg.contains('whatsapp')) {
          throw Exception('wa_profile_column_missing');
        }
      }
      return null;
    }
  }

  List<Part> _parts = const [];
  List<Part> listParts() => _parts;

  List<Job> _jobs = const [];
  List<Job> listJobs() => _jobs;

  final Map<String, List<JobPart>> _jobPartsByJobId = {};
  List<JobPart> listJobParts(String jobId) =>
      _jobPartsByJobId[jobId] ?? const [];

  List<InvoiceSummary> _invoices = const [];
  List<InvoiceSummary> listInvoices() => _invoices;

  List<PaymentAccount> _paymentAccounts = const [];
  List<PaymentAccount> listPaymentAccounts() => _paymentAccounts;

  PaymentAccount? get primaryPaymentAccount {
    for (final a in _paymentAccounts) {
      if (a.isActive) return a;
    }
    return null;
  }

  List<AttendanceRecord> _attendance = const [];
  List<AttendanceRecord> listAttendance() => _attendance;

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> _loadRewardFlags() async {
    final actor = _profile;
    if (actor == null) return;
    if (actor.role != AppRole.pelanggan) {
      _gmapsReviewed = false;
      return;
    }
    try {
      final row = await _client
          .from('customer_rewards')
          .select('gmaps_reviewed')
          .eq('customer_id', actor.userId)
          .maybeSingle();
      _gmapsReviewed = (row?['gmaps_reviewed'] as bool?) ?? false;
    } catch (_) {
      _gmapsReviewed = false;
    }
  }

  Future<void> setGmapsReviewed({required bool reviewed}) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.pelanggan) throw Exception('forbidden');
    try {
      await _client.from('customer_rewards').upsert({
        'customer_id': actor.userId,
        'gmaps_reviewed': reviewed,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
    _gmapsReviewed = reviewed;
    notifyListeners();
  }

  RealtimeChannel? _rtChannel;
  bool _rtSubscribed = false;

  Future<void> _stopRealtime() async {
    _rtSubscribed = false;
    final c = _rtChannel;
    _rtChannel = null;
    if (c != null) {
      try {
        await _client.removeChannel(c);
      } catch (_) {}
    }
  }

  void _startRealtimeIfNeeded() {
    final actor = _profile;
    if (actor == null) return;
    if (_rtSubscribed) return;

    _rtSubscribed = true;
    _rtChannel ??= _client.channel('gg_realtime_v1');

    void scheduleRefresh() {
      _scheduleRealtimeRefresh();
    }

    _rtChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) => scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'vehicles',
          callback: (_) => scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jobs',
          callback: (_) => scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'job_parts',
          callback: (_) => scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoices',
          callback: (_) => scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoice_items',
          callback: (_) => scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          callback: (_) => scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'parts',
          callback: (_) => scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'service_types',
          callback: (_) => scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'service_subtypes',
          callback: (_) => scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'service_subtype_parts',
          callback: (_) => scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance',
          callback: (_) => scheduleRefresh(),
        )
        .subscribe();
    _startBookingAutoRefresh();
  }

  bool _rtRefreshScheduled = false;

  void _scheduleRealtimeRefresh() {
    if (_rtRefreshScheduled) return;
    _rtRefreshScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 450)).then((_) async {
      _rtRefreshScheduled = false;
      if (_profile == null) return;
      try {
        await refreshAll();
      } catch (_) {}
    });
  }

  Future<void> init({bool force = false}) async {
    if (_initialized && !force) {
      return;
    }
    if (_initializing) {
      return;
    }
    _initializing = true;
    _initError = null;

    try {
      await _loadLocalThemeMode();
      if (!_enableSupabase || const bool.fromEnvironment('FLUTTER_TEST')) {
        _initialized = true;
        notifyListeners();
        return;
      }

      if (!isSupabaseConfigured) {
        throw Exception('supabase_not_configured');
      }

      await Supabase.initialize(
        url: GGSupabaseConfig.url,
        anonKey: GGSupabaseConfig.anonKey,
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
      ).timeout(const Duration(seconds: 12));

      final session = _client.auth.currentSession;
      if (session != null) {
        await _loadProfileFromSupabase();
        await refreshAll();
        await _loadRewardFlags();
        _startRealtimeIfNeeded();
      }

      _client.auth.onAuthStateChange.listen((event) async {
        if (event.session == null) {
          await _stopRealtime();
          _stopBookingAutoRefresh();
          _profile = null;
          _whatsappNumber = null;
          _gmapsReviewed = null;
          _vehicles = const [];
          _bookings = const [];
          _enginePresets = const [];
          _parts = const [];
          _jobs = const [];
          _jobPartsByJobId.clear();
          _invoices = const [];
          _attendance = const [];
          _staff = const [];
          _customers = const [];
          notifyListeners();
          return;
        }
        await _loadProfileFromSupabase();
        await refreshAll();
        await _loadRewardFlags();
        _startRealtimeIfNeeded();
      });

      _initialized = true;
      notifyListeners();
    } catch (e) {
      _initError = e.toString();
      _initialized = true;
      notifyListeners();
    } finally {
      _initializing = false;
    }
  }

  Future<void> reinitialize() async {
    _initialized = false;
    _initError = null;
    notifyListeners();
    await init(force: true);
  }

  Future<void> forceSignOutToLogin() async {
    try {
      final client = Supabase.instance.client;
      await client.auth.signOut();
    } catch (_) {}
    await _stopRealtime();
    _stopBookingAutoRefresh();
    _profile = null;
    _whatsappNumber = null;
    _gmapsReviewed = null;
    _vehicles = const [];
    _bookings = const [];
    _enginePresets = const [];
    _parts = const [];
    _jobs = const [];
    _jobPartsByJobId.clear();
    _invoices = const [];
    _attendance = const [];
    _staff = const [];
    _customers = const [];
    _initError = null;
    _initialized = true;
    notifyListeners();
  }

  Future<AppRole> _fetchRoleFromRpc() async {
    try {
      final res = await _client.rpc('gg_current_role');
      final roleStr = res?.toString() ?? '';
      return AppRoleX.tryParse(roleStr) ?? AppRole.pelanggan;
    } catch (_) {
      return AppRole.pelanggan;
    }
  }

  Future<void> _loadProfileFromSupabase() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _profile = null;
      _whatsappNumber = null;
      notifyListeners();
      return;
    }

    final roleFromRpc = await _fetchRoleFromRpc();

    Map<String, dynamic>? row;
    try {
      row = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (_) {
      row = null;
    }
    if (row == null) {
      _profile = UserProfile(
        userId: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name']?.toString() ?? '',
        role: roleFromRpc,
        isActive: true,
        mustChangePassword: false,
      );
      _themeMode = _parseThemeMode(user.userMetadata?['theme_mode']);
      _whatsappNumber = _pickWhatsappFromProfileRow(
        (user.userMetadata ?? const <String, dynamic>{}),
      );
      notifyListeners();
      return;
    }

    final roleStr = row['role']?.toString() ?? roleFromRpc.name;
    _profile = UserProfile(
      userId: user.id,
      email: user.email ?? row['email']?.toString() ?? '',
      fullName: row['full_name']?.toString() ?? '',
      role: AppRoleX.tryParse(roleStr) ?? AppRole.pelanggan,
      isActive: (row['is_active'] as bool?) ?? true,
      mustChangePassword: (row['must_change_password'] as bool?) ?? false,
    );
    _themeMode = _parseThemeMode(
      user.userMetadata?['theme_mode'] ?? row['theme_mode'],
    );
    await _saveLocalThemeMode();
    _whatsappNumber =
        _pickWhatsappFromProfileRow((row as Map).cast<String, dynamic>()) ??
        _pickWhatsappFromProfileRow(user.userMetadata ?? const {});
    unawaited(_syncWhatsappToProfileIfMissing());
    notifyListeners();
  }

  Future<void> refreshAll() async {
    final actor = _profile;
    if (actor == null) {
      return;
    }
    final futures = <Future<void>>[
      _refreshVehicles(),
      _refreshBookings(),
      _refreshEnginePresets(),
      _refreshServiceCatalog(),
      _refreshParts(),
      _refreshJobsAndJobParts(),
      _refreshPaymentAccounts(),
      _refreshInvoices(),
      _refreshStaff(),
    ];
    if (actor.role == AppRole.admin || actor.role == AppRole.owner) {
      futures.add(_refreshCustomers());
    }
    if (actor.role != AppRole.pelanggan) {
      futures.add(_refreshAttendance());
    }
    await Future.wait(futures);
    notifyListeners();
  }

  Future<void> _refreshPaymentAccounts() async {
    final actor = _profile;
    if (actor == null) return;
    try {
      final rows = await _client
          .from('payment_accounts')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: true);
      _paymentAccounts = (rows as List)
          .map(
            (r) => PaymentAccount.fromJson((r as Map).cast<String, Object?>()),
          )
          .where((a) => a.id.isNotEmpty)
          .toList();
    } catch (_) {
      _paymentAccounts = const [];
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    await _loadProfileFromSupabase();
    await refreshAll();
    await _loadRewardFlags();
    _startRealtimeIfNeeded();
  }

  Future<void> signUpCustomer({
    required String fullName,
    required String whatsapp,
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          if (whatsapp.trim().isNotEmpty) 'whatsapp': whatsapp.trim(),
        },
      );
    } on AuthApiException catch (e) {
      final sc = e.statusCode?.toString();
      if (sc == '400' && e.code == 'email_provider_disabled') {
        throw Exception(
          'email_signups_disabled: Email signups dimatikan di Supabase Auth. '
          'Aktifkan Email provider + pastikan signups tidak diblokir di Authentication settings.',
        );
      }
      if (sc == '429' && e.code == 'over_email_send_rate_limit') {
        throw Exception(
          'email_rate_limit_exceeded: Supabase membatasi pengiriman email signup (429). '
          'Tunggu beberapa saat, atau matikan Email Confirmations agar signup tidak kirim email.',
        );
      }
      rethrow;
    }
    await _client.auth.signInWithPassword(email: email, password: password);
    await _loadProfileFromSupabase();
    if (whatsapp.trim().isNotEmpty) {
      await setWhatsappNumber(whatsapp);
    }
    await refreshAll();
    await _loadRewardFlags();
    _startRealtimeIfNeeded();
  }

  Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await _stopRealtime();
    _stopBookingAutoRefresh();
    _profile = null;
    _whatsappNumber = null;
    _gmapsReviewed = null;
    _vehicles = const [];
    _bookings = const [];
    _enginePresets = const [];
    _serviceTypes = const [];
    _serviceSubtypes = const [];
    _serviceSubtypeParts = const [];
    _serviceCatalogError = null;
    _parts = const [];
    _jobs = const [];
    _jobPartsByJobId.clear();
    _invoices = const [];
    _attendance = const [];
    _staff = const [];
    _customers = const [];
    notifyListeners();
  }

  Future<UserProfile> createStaff({
    required String fullName,
    required String email,
    required String password,
    required AppRole role,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin) throw Exception('forbidden');

    final cleanName = fullName.trim();
    final cleanEmail = email.trim();
    if (cleanName.isEmpty) throw Exception('name_required');
    if (cleanEmail.isEmpty) throw Exception('email_required');
    if (password.isEmpty) throw Exception('password_required');
    if (role == AppRole.pelanggan) throw Exception('invalid_role');

    if (isMockMode) {
      final id = 'staff-${DateTime.now().millisecondsSinceEpoch}';
      final created = UserProfile(
        userId: id,
        email: cleanEmail,
        fullName: cleanName,
        role: role,
        isActive: true,
        mustChangePassword: true,
      );
      _staff = [created, ..._staff];
      notifyListeners();
      return created;
    }

    if (!isSupabaseConfigured) {
      throw Exception('supabase_not_configured');
    }

    final bootstrapClient = SupabaseClient(
      GGSupabaseConfig.url,
      GGSupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    AuthResponse authRes;
    try {
      authRes = await bootstrapClient.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'full_name': cleanName},
      );
    } on AuthApiException catch (e) {
      final sc = e.statusCode?.toString();
      if (sc == '400' && e.code == 'email_provider_disabled') {
        throw Exception(
          'email_signups_disabled: Email signups dimatikan di Supabase Auth. '
          'Aktifkan Email provider + pastikan signups tidak diblokir di Authentication settings.',
        );
      }
      if (sc == '429' && e.code == 'over_email_send_rate_limit') {
        throw Exception(
          'email_rate_limit_exceeded: Supabase membatasi pengiriman email signup (429). '
          'Tunggu beberapa saat, atau matikan Email Confirmations di Auth settings agar signup tidak kirim email.',
        );
      }
      rethrow;
    }
    final newUser = authRes.user;
    if (newUser == null) {
      throw Exception('create_user_failed');
    }

    final payload = <String, Object?>{
      'id': newUser.id,
      'email': cleanEmail,
      'full_name': cleanName,
      'role': role.name,
      'is_active': true,
      'must_change_password': true,
    };

    try {
      await _client.from('profiles').upsert(payload);
    } catch (_) {
      await _client.from('profiles').update(payload).eq('id', newUser.id);
    }

    await _refreshStaff();
    notifyListeners();

    for (final s in _staff) {
      if (s.userId == newUser.id) return s;
    }
    return UserProfile(
      userId: newUser.id,
      email: cleanEmail,
      fullName: cleanName,
      role: role,
      isActive: true,
      mustChangePassword: true,
    );
  }

  Future<UserProfile> upsertStaffProfile({
    required String userId,
    required String fullName,
    required String email,
    required AppRole role,
    bool isActive = true,
    bool mustChangePassword = true,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin) throw Exception('forbidden');

    final cleanId = userId.trim();
    final cleanName = fullName.trim();
    final cleanEmail = email.trim();
    if (cleanId.isEmpty) throw Exception('user_id_required');
    if (cleanName.isEmpty) throw Exception('name_required');
    if (cleanEmail.isEmpty) throw Exception('email_required');
    if (role == AppRole.pelanggan) throw Exception('invalid_role');

    final payload = <String, Object?>{
      'id': cleanId,
      'email': cleanEmail,
      'full_name': cleanName,
      'role': role.name,
      'is_active': isActive,
      'must_change_password': mustChangePassword,
    };

    try {
      await _client.from('profiles').upsert(payload);
    } catch (_) {
      await _client.from('profiles').update(payload).eq('id', cleanId);
    }

    await _refreshStaff();
    notifyListeners();
    for (final s in _staff) {
      if (s.userId == cleanId) return s;
    }
    return UserProfile(
      userId: cleanId,
      email: cleanEmail,
      fullName: cleanName,
      role: role,
      isActive: isActive,
      mustChangePassword: mustChangePassword,
    );
  }

  Future<List<UserProfile>> listStaff() async {
    await _refreshStaff();
    return _staff;
  }

  Future<void> _refreshAttendance() async {
    final actor = _profile;
    if (actor == null) return;

    try {
      final now = DateTime.now();
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 14));

      dynamic query = _client
          .from('attendance')
          .select()
          .gte('work_date', _toDateString(start))
          .order('work_date', ascending: false)
          .order('check_in', ascending: false);

      if (actor.role != AppRole.admin && actor.role != AppRole.owner) {
        query = query.eq('staff_id', actor.userId);
      }

      final rows = await query;
      _attendance = (rows as List)
          .map((r) => AttendanceRecord.fromJson(_mapAttendanceRow(r as Map)))
          .toList();
    } catch (_) {
      _attendance = const [];
    }
  }

  AttendanceRecord? findMyTodayAttendance() {
    final actor = _profile;
    if (actor == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final a in _attendance) {
      if (a.staffId != actor.userId) continue;
      final d = DateTime(a.workDate.year, a.workDate.month, a.workDate.day);
      if (d == today) return a;
    }
    return null;
  }

  Future<AttendanceRecord?> getMyTodayAttendance() async {
    final actor = _profile;
    if (actor == null) return null;
    final now = DateTime.now();
    final dateStr = _toDateString(DateTime(now.year, now.month, now.day));
    final row = await _client
        .from('attendance')
        .select()
        .eq('staff_id', actor.userId)
        .eq('work_date', dateStr)
        .maybeSingle();
    if (row == null) return null;
    return AttendanceRecord.fromJson(_mapAttendanceRow(row));
  }

  Future<List<AttendanceRecord>> listAttendanceByDate(DateTime date) async {
    final dateStr = _toDateString(DateTime(date.year, date.month, date.day));
    final rows = await _client
        .from('attendance')
        .select()
        .eq('work_date', dateStr)
        .order('check_in', ascending: true);
    return (rows as List)
        .map((r) => AttendanceRecord.fromJson(_mapAttendanceRow(r as Map)))
        .toList();
  }

  Future<AttendanceRecord> attendanceCheckIn() async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role == AppRole.pelanggan) throw Exception('forbidden');

    final now = DateTime.now();
    final dateStr = _toDateString(DateTime(now.year, now.month, now.day));
    final existing = await _client
        .from('attendance')
        .select('id,check_in')
        .eq('staff_id', actor.userId)
        .eq('work_date', dateStr)
        .maybeSingle();
    if (existing != null) {
      final row = await _client
          .from('attendance')
          .select()
          .eq('id', existing['id'])
          .single();
      final rec = AttendanceRecord.fromJson(_mapAttendanceRow(row as Map));
      await _refreshAttendance();
      notifyListeners();
      return rec;
    }

    final row = await _client
        .from('attendance')
        .insert({
          'staff_id': actor.userId,
          'work_date': dateStr,
          'check_in': now.toUtc().toIso8601String(),
        })
        .select()
        .single();
    final rec = AttendanceRecord.fromJson(_mapAttendanceRow(row as Map));
    await _refreshAttendance();
    notifyListeners();
    return rec;
  }

  Future<AttendanceRecord> attendanceBreakStart() async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role == AppRole.pelanggan) throw Exception('forbidden');

    final now = DateTime.now();
    final dateStr = _toDateString(DateTime(now.year, now.month, now.day));
    final row0 = await _client
        .from('attendance')
        .select()
        .eq('staff_id', actor.userId)
        .eq('work_date', dateStr)
        .maybeSingle();
    if (row0 == null) throw Exception('not_checked_in');
    if (row0['check_out'] != null) throw Exception('already_checked_out');
    if (row0['break_start'] != null && row0['break_end'] == null) {
      throw Exception('already_on_break');
    }
    if (row0['break_start'] != null && row0['break_end'] != null) {
      throw Exception('break_already_used');
    }

    final row = await _client
        .from('attendance')
        .update({'break_start': now.toUtc().toIso8601String()})
        .eq('id', row0['id'])
        .select()
        .single();
    final rec = AttendanceRecord.fromJson(_mapAttendanceRow(row as Map));
    await _refreshAttendance();
    notifyListeners();
    return rec;
  }

  Future<AttendanceRecord> attendanceBreakEnd() async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role == AppRole.pelanggan) throw Exception('forbidden');

    final now = DateTime.now();
    final dateStr = _toDateString(DateTime(now.year, now.month, now.day));
    final row0 = await _client
        .from('attendance')
        .select()
        .eq('staff_id', actor.userId)
        .eq('work_date', dateStr)
        .maybeSingle();
    if (row0 == null) throw Exception('not_checked_in');
    if (row0['check_out'] != null) throw Exception('already_checked_out');
    if (row0['break_start'] == null) throw Exception('break_not_started');
    if (row0['break_end'] != null) throw Exception('break_already_ended');

    final row = await _client
        .from('attendance')
        .update({'break_end': now.toUtc().toIso8601String()})
        .eq('id', row0['id'])
        .select()
        .single();
    final rec = AttendanceRecord.fromJson(_mapAttendanceRow(row as Map));
    await _refreshAttendance();
    notifyListeners();
    return rec;
  }

  Future<AttendanceRecord> attendanceCheckOut() async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role == AppRole.pelanggan) throw Exception('forbidden');

    final now = DateTime.now();
    final dateStr = _toDateString(DateTime(now.year, now.month, now.day));
    final row0 = await _client
        .from('attendance')
        .select()
        .eq('staff_id', actor.userId)
        .eq('work_date', dateStr)
        .maybeSingle();
    if (row0 == null) throw Exception('not_checked_in');
    if (row0['check_out'] != null) {
      final rec = AttendanceRecord.fromJson(_mapAttendanceRow(row0 as Map));
      await _refreshAttendance();
      notifyListeners();
      return rec;
    }
    if (row0['break_start'] != null && row0['break_end'] == null) {
      throw Exception('finish_break_first');
    }

    final row = await _client
        .from('attendance')
        .update({'check_out': now.toUtc().toIso8601String()})
        .eq('id', row0['id'])
        .select()
        .single();
    final rec = AttendanceRecord.fromJson(_mapAttendanceRow(row as Map));
    await _refreshAttendance();
    notifyListeners();
    return rec;
  }

  Future<void> _refreshStaff() async {
    final actor = _profile;
    if (actor == null) return;
    final rows = await _client
        .from('profiles')
        .select()
        .neq('role', 'pelanggan');
    _staff = (rows as List)
        .map(
          (r) => UserProfile(
            userId: r['id']?.toString() ?? '',
            email: r['email']?.toString() ?? '',
            fullName: r['full_name']?.toString() ?? '',
            role:
                AppRoleX.tryParse(r['role']?.toString() ?? '') ??
                AppRole.pelanggan,
            isActive: (r['is_active'] as bool?) ?? true,
            mustChangePassword: (r['must_change_password'] as bool?) ?? false,
          ),
        )
        .toList();
  }

  Future<void> _refreshCustomers() async {
    final actor = _profile;
    if (actor == null) return;
    if (actor.role != AppRole.admin && actor.role != AppRole.owner) return;
    final rows = await _client
        .from('profiles')
        .select()
        .eq('role', 'pelanggan');
    _customers = (rows as List)
        .map(
          (r) => UserProfile(
            userId: r['id']?.toString() ?? '',
            email: r['email']?.toString() ?? '',
            fullName: r['full_name']?.toString() ?? '',
            role: AppRole.pelanggan,
            isActive: (r['is_active'] as bool?) ?? true,
            mustChangePassword: (r['must_change_password'] as bool?) ?? false,
          ),
        )
        .toList();
  }

  Future<List<StockMovement>> fetchStockMovements({
    required DateTime start,
    required DateTime end,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin && actor.role != AppRole.owner) {
      throw Exception('forbidden');
    }
    final rows = await _client
        .from('stock_movements')
        .select()
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at', ascending: false);
    return (rows as List).map((r) {
      return StockMovement.fromJson(_mapStockMovementRow(r as Map));
    }).toList();
  }

  Future<void> _refreshVehicles() async {
    final actor = _profile;
    if (actor == null) return;
    dynamic query = _client.from('vehicles').select();
    if (actor.role == AppRole.pelanggan) {
      query = query.eq('customer_id', actor.userId);
    }
    query = query.order('created_at', ascending: false);
    final rows = await query;
    _vehicles = (rows as List)
        .map((r) => Vehicle.fromJson(_mapVehicleRow(r as Map)))
        .toList();
  }

  Future<Vehicle> upsertVehicle({
    String? id,
    required String plate,
    required String brand,
    required String model,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');

    final payload = <String, Object?>{
      if (id != null) 'id': id,
      'customer_id': actor.userId,
      'plate_number': plate,
      'brand': brand,
      'model': model,
    };

    final row = await _client
        .from('vehicles')
        .upsert(payload)
        .select()
        .single();
    final v = Vehicle.fromJson(
      _mapVehicleRow((row as Map).cast<String, Object?>()),
    );
    await _refreshVehicles();
    notifyListeners();
    return v;
  }

  Future<void> deleteVehicle(String id) async {
    await _client.from('vehicles').delete().eq('id', id);
    await _refreshVehicles();
    notifyListeners();
  }

  Future<void> _refreshBookings() async {
    final actor = _profile;
    if (actor == null) return;
    dynamic query = _client.from('bookings').select();
    if (actor.role == AppRole.pelanggan) {
      query = query.eq('customer_id', actor.userId);
    }
    query = query.order('created_at', ascending: false);
    final rows = await query;
    _bookings = (rows as List)
        .map((r) => Booking.fromJson(_mapBookingRow(r as Map)))
        .toList();
  }

  Future<Booking> createBooking({
    required BookingType type,
    required DateTime date,
    required String time,
    required String complaint,
    required String? vehicleId,
    String? serviceTypeId,
    String? serviceSubtypeId,
    Map<String, Object?>? modifPayload,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    BookingRules.validateSlot(date: date, time: time);
    if (type == BookingType.modif) {
      if (time != '08:00') throw Exception('upgrade_time_only_0800');
      final dateStr = _toDateString(date);
      final rows = await _client
          .from('bookings')
          .select('id')
          .eq('type', 'modif')
          .eq('booking_date', dateStr)
          .inFilter('status', ['pending', 'confirmed', 'checked_in', 'done'])
          .limit(1);
      if ((rows as List).isNotEmpty) {
        throw Exception('upgrade_slot_full');
      }
    }

    final payload = <String, Object?>{
      'customer_id': actor.userId,
      'vehicle_id': vehicleId,
      'booking_date': _toDateString(date),
      'booking_time': time,
      'type': type.name,
      'complaint': complaint,
      if (_whatsappNumber != null && _whatsappNumber!.trim().isNotEmpty)
        'customer_whatsapp': _whatsappNumber!.trim(),
      'modif_payload': modifPayload,
      'status': 'pending',
    };
    if (serviceTypeId != null) {
      payload['service_type_id'] = serviceTypeId;
    }
    if (serviceSubtypeId != null) {
      payload['service_subtype_id'] = serviceSubtypeId;
    }
    dynamic row;
    try {
      row = await _client.from('bookings').insert(payload).select().single();
    } catch (e) {
      final msg = e.toString();
      final isSchemaMismatch =
          msg.contains('service_type_id') ||
          msg.contains('service_subtype_id') ||
          msg.contains('customer_whatsapp') ||
          msg.contains('column') ||
          msg.contains('schema cache');
      if (!isSchemaMismatch) rethrow;

      payload.remove('service_type_id');
      payload.remove('service_subtype_id');
      payload.remove('customer_whatsapp');
      row = await _client.from('bookings').insert(payload).select().single();
    }
    await _refreshBookings();
    final b = Booking.fromJson(
      _mapBookingRow((row as Map).cast<String, Object?>()),
    );
    notifyListeners();
    return b;
  }

  Future<Booking> rescheduleBookingCustomer({
    required String bookingId,
    required DateTime newDate,
    required String newTime,
  }) async {
    BookingRules.validateSlot(date: newDate, time: newTime);
    final existing = await _client
        .from('bookings')
        .select('type')
        .eq('id', bookingId)
        .maybeSingle();
    final type = existing?['type']?.toString();
    if (type == BookingType.modif.name) {
      if (newTime != '08:00') throw Exception('upgrade_time_only_0800');
      final dateStr = _toDateString(newDate);
      final rows = await _client
          .from('bookings')
          .select('id')
          .eq('type', 'modif')
          .eq('booking_date', dateStr)
          .neq('id', bookingId)
          .inFilter('status', ['pending', 'confirmed', 'checked_in', 'done'])
          .limit(1);
      if ((rows as List).isNotEmpty) {
        throw Exception('upgrade_slot_full');
      }
    }
    final row = await _client
        .from('bookings')
        .update({
          'booking_date': _toDateString(newDate),
          'booking_time': newTime,
        })
        .eq('id', bookingId)
        .select()
        .single();
    final b = Booking.fromJson(
      _mapBookingRow((row as Map).cast<String, Object?>()),
    );
    await _refreshBookings();
    notifyListeners();
    return b;
  }

  Future<Booking> updateBookingAdmin({
    required String bookingId,
    BookingStatus? setStatus,
    DateTime? newDate,
    String? newTime,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin) throw Exception('forbidden');

    if (newDate != null || newTime != null) {
      final existing = await _client
          .from('bookings')
          .select('booking_date, booking_time, type')
          .eq('id', bookingId)
          .single();
      final existingDate = DateTime.parse(
        existing['booking_date']?.toString() ??
            DateTime.now().toIso8601String(),
      );
      final existingTime = existing['booking_time']?.toString() ?? '08:00';
      final type = existing['type']?.toString();
      BookingRules.validateSlot(
        date: newDate ?? existingDate,
        time: newTime ?? existingTime,
      );
      if (type == BookingType.modif.name) {
        final time = newTime ?? existingTime;
        final date = newDate ?? existingDate;
        if (time != '08:00') throw Exception('upgrade_time_only_0800');
        final dateStr = _toDateString(date);
        final rows = await _client
            .from('bookings')
            .select('id')
            .eq('type', 'modif')
            .eq('booking_date', dateStr)
            .neq('id', bookingId)
            .inFilter('status', ['pending', 'confirmed', 'checked_in', 'done'])
            .limit(1);
        if ((rows as List).isNotEmpty) {
          throw Exception('upgrade_slot_full');
        }
      }
    }

    final patch = <String, Object?>{};
    if (setStatus != null) {
      patch['status'] = _bookingStatusToDb(setStatus);
      if (setStatus == BookingStatus.confirmed) {
        patch['confirmed_by'] = actor.userId;
        patch['confirmed_at'] = DateTime.now().toIso8601String();
      }
    }
    if (newDate != null) patch['booking_date'] = _toDateString(newDate);
    if (newTime != null) patch['booking_time'] = newTime;

    final row = await _client
        .from('bookings')
        .update(patch)
        .eq('id', bookingId)
        .select()
        .single();
    final b = Booking.fromJson(
      _mapBookingRow((row as Map).cast<String, Object?>()),
    );
    await _refreshBookings();
    notifyListeners();
    return b;
  }

  Future<void> _refreshEnginePresets() async {
    final rows = await _client.from('engine_presets').select().order('brand');
    _enginePresets = (rows as List)
        .map((r) => EnginePreset.fromJson((r as Map).cast<String, Object?>()))
        .toList();
  }

  Future<void> _refreshServiceCatalog() async {
    try {
      _serviceCatalogError = null;
      final typeRows = await _client
          .from('service_types')
          .select()
          .order('name');
      _serviceTypes = (typeRows as List)
          .map((r) => ServiceType.fromRow((r as Map).cast<String, Object?>()))
          .where((t) => t.id.isNotEmpty)
          .toList();

      final subtypeRows = await _client
          .from('service_subtypes')
          .select()
          .order('name');
      _serviceSubtypes = (subtypeRows as List)
          .map(
            (r) => ServiceSubtype.fromRow((r as Map).cast<String, Object?>()),
          )
          .where((s) => s.id.isNotEmpty)
          .toList();

      final bomRows = await _client.from('service_subtype_parts').select();
      _serviceSubtypeParts = (bomRows as List)
          .map(
            (r) =>
                ServiceSubtypePart.fromRow((r as Map).cast<String, Object?>()),
          )
          .where((x) => x.id.isNotEmpty)
          .toList();
    } catch (e) {
      _serviceCatalogError = e.toString();
      _serviceTypes = const [];
      _serviceSubtypes = const [];
      _serviceSubtypeParts = const [];
    }
  }

  Future<void> _refreshParts() async {
    final actor = _profile;
    if (actor == null) return;
    final rows = await _client.from('parts').select().order('sku');
    _parts = (rows as List)
        .map((r) => Part.fromJson(_mapPartRow(r as Map)))
        .toList();
  }

  Part? findPartBySku(String sku) {
    for (final p in _parts) {
      if (p.sku.toLowerCase() == sku.toLowerCase()) return p;
    }
    return null;
  }

  Future<int> addStockIn({
    required String partId,
    required int qty,
    required String note,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin) throw Exception('forbidden');
    if (qty <= 0) throw Exception('qty_invalid');

    final current = await _client
        .from('parts')
        .select('id, stock_on_hand')
        .eq('id', partId)
        .single();
    final currentQty = (current['stock_on_hand'] as num?)?.toInt() ?? 0;

    final updated = await _client
        .from('parts')
        .update({'stock_on_hand': currentQty + qty})
        .eq('id', partId)
        .select('stock_on_hand')
        .single();
    final newQty =
        (updated['stock_on_hand'] as num?)?.toInt() ?? (currentQty + qty);

    await _client
        .from('stock_movements')
        .insert({
          'part_id': partId,
          'type': 'in',
          'qty': qty,
          'note': note,
          'ref_type': 'manual',
          'ref_id': null,
          'created_by': actor.userId,
        })
        .select('id')
        .single();
    await _refreshParts();
    notifyListeners();
    return newQty;
  }

  Future<Part> upsertPart({
    String? id,
    required String sku,
    required String name,
    required String unit,
    required num sellPrice,
    required num buyPrice,
    required int minStock,
    required bool isActive,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin) throw Exception('forbidden');

    final payload = <String, Object?>{
      'sku': sku,
      'name': name,
      'unit': unit,
      'sell_price': sellPrice,
      'buy_price': buyPrice,
      'min_stock': minStock,
      'is_active': isActive,
    };
    dynamic row;
    if (id == null) {
      row = await _client.from('parts').insert(payload).select().single();
    } else {
      row = await _client
          .from('parts')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
    }
    final part = Part.fromJson(
      _mapPartRow((row as Map).cast<String, Object?>()),
    );
    await _refreshParts();
    notifyListeners();
    return part;
  }

  Future<void> _refreshJobsAndJobParts() async {
    final actor = _profile;
    if (actor == null) return;
    dynamic query = _client.from('jobs').select();
    if (actor.role == AppRole.pelanggan) {
      query = query.eq('customer_id', actor.userId);
    }
    query = query.order('created_at', ascending: false);
    final rows = await query;
    _jobs = (rows as List)
        .map((r) => Job.fromJson(_mapJobRow(r as Map)))
        .toList();

    _jobPartsByJobId.clear();
    if (_jobs.isEmpty) return;
    final jobIds = _jobs.map((j) => j.id).toList();
    final jpRows = await _client
        .from('job_parts')
        .select()
        .inFilter('job_id', jobIds);
    final mapped = (jpRows as List)
        .map((r) => JobPart.fromJson(_mapJobPartRow(r as Map)))
        .toList();
    for (final jp in mapped) {
      final list = _jobPartsByJobId.putIfAbsent(jp.jobId, () => <JobPart>[]);
      list.add(jp);
    }
  }

  Future<Job> checkInBooking({required String bookingId}) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin) throw Exception('forbidden');

    final bookingRow = await _client
        .from('bookings')
        .select()
        .eq('id', bookingId)
        .single();
    final booking = Booking.fromJson(
      _mapBookingRow((bookingRow as Map).cast<String, Object?>()),
    );
    await _client
        .from('bookings')
        .update({'status': 'checked_in'})
        .eq('id', bookingId);

    final jobRow = await _client
        .from('jobs')
        .insert({
          'booking_id': bookingId,
          'customer_id': booking.customerId,
          'vehicle_id': booking.vehicleId,
          'assigned_mechanic_id': null,
          'status': 'draft',
          'complaint': booking.complaint,
          'note': '',
        })
        .select()
        .single();

    final job = Job.fromJson(
      _mapJobRow((jobRow as Map).cast<String, Object?>()),
    );
    if (booking.type == BookingType.modif) {
      final payload = booking.modifPayload;
      final raw = payload == null ? null : payload['inventory_bom'];
      if (raw is List) {
        final byPartId = <String, int>{};
        for (final it in raw) {
          if (it is! Map) continue;
          final partId = it['inventory_part_id']?.toString() ?? '';
          if (partId.isEmpty) continue;
          final qty = (it['qty'] as num?)?.toInt() ?? 1;
          if (qty <= 0) continue;
          byPartId[partId] = (byPartId[partId] ?? 0) + qty;
        }
        if (byPartId.isNotEmpty) {
          final inserts = <Map<String, Object?>>[];
          for (final e in byPartId.entries) {
            inserts.add({'job_id': job.id, 'part_id': e.key, 'qty': e.value});
          }
          await _client.from('job_parts').insert(inserts);
        }
      }
    }
    await _refreshBookings();
    await _refreshJobsAndJobParts();
    notifyListeners();
    return job;
  }

  Future<Job> assignMechanic({
    required String jobId,
    required String mechanicUserId,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin) throw Exception('forbidden');

    final job0 = await _client
        .from('jobs')
        .select('booking_id')
        .eq('id', jobId)
        .maybeSingle();
    final bookingId = job0 == null
        ? ''
        : (job0['booking_id']?.toString() ?? '');
    if (bookingId.isNotEmpty) {
      final b = await _client
          .from('bookings')
          .select('type, booking_date')
          .eq('id', bookingId)
          .maybeSingle();
      final bookingType = b == null ? '' : (b['type']?.toString() ?? '');
      final bookingDateStr = b == null
          ? ''
          : (b['booking_date']?.toString() ?? '');
      if (bookingType == 'modif' && bookingDateStr.isNotEmpty) {
        bool conflictFound = false;
        try {
          final rows = await _client
              .from('jobs')
              .select('id, bookings!inner(booking_date)')
              .eq('assigned_mechanic_id', mechanicUserId)
              .neq('id', jobId)
              .neq('status', 'cancelled')
              .eq('bookings.booking_date', bookingDateStr)
              .limit(1);
          conflictFound = (rows as List).isNotEmpty;
        } catch (_) {
          final rows = await _client
              .from('jobs')
              .select('id, booking_id, status')
              .eq('assigned_mechanic_id', mechanicUserId)
              .neq('id', jobId)
              .neq('status', 'cancelled')
              .limit(200);
          final bookingIds = (rows as List)
              .map((r) => (r as Map)['booking_id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
          if (bookingIds.isNotEmpty) {
            final bRows = await _client
                .from('bookings')
                .select('id, booking_date')
                .inFilter('id', bookingIds);
            final dateByBookingId = <String, String>{};
            for (final r in (bRows as List)) {
              final m = (r as Map).cast<String, Object?>();
              final id = m['id']?.toString() ?? '';
              final d = m['booking_date']?.toString() ?? '';
              if (id.isNotEmpty && d.isNotEmpty) {
                dateByBookingId[id] = d;
              }
            }
            for (final r in rows) {
              final m = (r as Map).cast<String, Object?>();
              final bid = m['booking_id']?.toString() ?? '';
              if (bid.isEmpty) continue;
              if (dateByBookingId[bid] == bookingDateStr) {
                conflictFound = true;
                break;
              }
            }
          }
        }
        if (conflictFound) {
          throw Exception('mechanic_daily_quota_full');
        }
      }
    }

    final row = await _client
        .from('jobs')
        .update({'assigned_mechanic_id': mechanicUserId})
        .eq('id', jobId)
        .select()
        .single();
    final job = Job.fromJson(_mapJobRow((row as Map).cast<String, Object?>()));
    await _refreshJobsAndJobParts();
    notifyListeners();
    return job;
  }

  Future<Job> updateJobStatus({
    required String jobId,
    required JobStatus status,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin) throw Exception('forbidden');

    final row = await _client
        .from('jobs')
        .update({'status': _jobStatusToDb(status)})
        .eq('id', jobId)
        .select()
        .single();
    final job = Job.fromJson(_mapJobRow((row as Map).cast<String, Object?>()));
    final shouldAutoCreateInvoice = status == JobStatus.done;
    final bookingId = job.bookingId?.trim() ?? '';
    if (bookingId.isNotEmpty) {
      final patch = <String, Object?>{};
      if (status == JobStatus.done) {
        patch['status'] = _bookingStatusToDb(BookingStatus.done);
      } else if (status == JobStatus.cancelled) {
        patch['status'] = _bookingStatusToDb(BookingStatus.cancelled);
      }
      if (patch.isNotEmpty) {
        try {
          await _client.from('bookings').update(patch).eq('id', bookingId);
        } catch (_) {}
      }
    }
    if (shouldAutoCreateInvoice) {
      await generateInvoiceFromJob(jobId: job.id);
    }
    await _refreshJobsAndJobParts();
    await _refreshBookings();
    notifyListeners();
    return job;
  }

  Future<Job> updateJobServiceInfo({
    required String jobId,
    ServicePriority? priority,
    int? etaMinutes,
    List<String>? serviceActions,
    String? note,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin) throw Exception('forbidden');

    final patch = <String, Object?>{};
    if (priority != null) patch['priority'] = priority.name;
    if (etaMinutes != null) patch['eta_minutes'] = etaMinutes;
    if (serviceActions != null) {
      patch['service_actions'] = serviceActions
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (note != null) patch['note'] = note;

    final row = await _client
        .from('jobs')
        .update(patch)
        .eq('id', jobId)
        .select()
        .single();
    final job = Job.fromJson(_mapJobRow((row as Map).cast<String, Object?>()));
    await _refreshJobsAndJobParts();
    notifyListeners();
    return job;
  }

  Future<JobPart> addJobPart({
    required String jobId,
    required String partId,
    required int qty,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin) throw Exception('forbidden');
    if (qty <= 0) throw Exception('qty_invalid');

    final row = await _client
        .from('job_parts')
        .insert({'job_id': jobId, 'part_id': partId, 'qty': qty})
        .select()
        .single();
    final jp = JobPart.fromJson(
      _mapJobPartRow((row as Map).cast<String, Object?>()),
    );
    await _refreshJobsAndJobParts();
    notifyListeners();
    return jp;
  }

  Future<void> _refreshInvoices() async {
    final actor = _profile;
    if (actor == null) return;
    dynamic query = _client.from('invoices').select();
    if (actor.role == AppRole.pelanggan) {
      final jobRows = await _client
          .from('jobs')
          .select()
          .eq('customer_id', actor.userId);
      final jobIds = (jobRows as List)
          .map((r) => (r as Map)['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      if (jobIds.isEmpty) {
        _invoices = const [];
        return;
      }
      query = query.inFilter('job_id', jobIds);
    }
    query = query.order('created_at', ascending: false);
    final invRows = await query;
    final invoices = (invRows as List)
        .map((r) => Invoice.fromJson(_mapInvoiceRow(r as Map)))
        .toList();
    if (invoices.isEmpty) {
      _invoices = const [];
      return;
    }

    final invIds = invoices.map((i) => i.id).toList();
    final itemRows = await _client
        .from('invoice_items')
        .select()
        .inFilter('invoice_id', invIds);
    final payRows = await _client
        .from('payments')
        .select()
        .inFilter('invoice_id', invIds);

    final items = (itemRows as List)
        .map((r) => InvoiceItem.fromJson((r as Map).cast<String, Object?>()))
        .toList();
    final pays = (payRows as List)
        .map((r) => InvoicePayment.fromJson(_mapPaymentRow(r as Map)))
        .toList();

    final itemsByInv = <String, List<InvoiceItem>>{};
    for (final it in items) {
      (itemsByInv[it.invoiceId] ??= <InvoiceItem>[]).add(it);
    }

    final paysByInv = <String, List<InvoicePayment>>{};
    for (final p in pays) {
      (paysByInv[p.invoiceId] ??= <InvoicePayment>[]).add(p);
    }

    _invoices = invoices
        .map(
          (inv) => InvoiceSummary(
            invoice: inv,
            items: itemsByInv[inv.id] ?? const [],
            payments: paysByInv[inv.id] ?? const [],
          ),
        )
        .toList();
  }

  Future<InvoiceSummary> generateInvoiceFromJob({required String jobId}) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin && actor.role != AppRole.kasir) {
      throw Exception('forbidden');
    }

    dynamic invoiceRow;
    final existing = await _client
        .from('invoices')
        .select()
        .eq('job_id', jobId)
        .maybeSingle();
    if (existing == null) {
      invoiceRow = await _client
          .from('invoices')
          .insert({'job_id': jobId, 'status': 'draft', 'discount': 0})
          .select()
          .single();
    } else {
      invoiceRow = existing;
    }
    final invoiceId = (invoiceRow as Map)['id']?.toString() ?? '';
    if (invoiceId.isEmpty) throw Exception('invoice_not_found');

    await _client
        .from('invoice_items')
        .delete()
        .eq('invoice_id', invoiceId)
        .eq('type', 'part');

    String serviceDesc = 'Jasa Servis';
    num serviceUnitPrice = 0;
    String? serviceSubtypeId;
    try {
      final jobRow = await _client
          .from('jobs')
          .select('booking_id')
          .eq('id', jobId)
          .maybeSingle();
      final bookingId = jobRow?['booking_id']?.toString() ?? '';
      if (bookingId.isNotEmpty) {
        final bookingRow = await _client
            .from('bookings')
            .select('type, service_subtype_id, modif_payload')
            .eq('id', bookingId)
            .maybeSingle();
        final bookingType = bookingRow?['type']?.toString() ?? '';
        if (bookingType == BookingType.service.name) {
          serviceSubtypeId =
              bookingRow?['service_subtype_id']?.toString().trim() ?? '';
          if (serviceSubtypeId.isNotEmpty) {
            final st = await _client
                .from('service_subtypes')
                .select('name, base_labor_price')
                .eq('id', serviceSubtypeId)
                .maybeSingle();
            final name = st?['name']?.toString() ?? '';
            if (name.isNotEmpty) serviceDesc = 'Jasa - $name';
            serviceUnitPrice = (st?['base_labor_price'] as num?) ?? 0;
          }
        } else if (bookingType == BookingType.modif.name) {
          serviceDesc = 'Jasa - Upgrade Mesin';
          final mp = bookingRow?['modif_payload'];
          if (mp is Map) {
            serviceUnitPrice = (mp['labor_price'] as num?) ?? 0;
          }
        }
      }
    } catch (_) {}

    final partQtyById = <String, int>{};
    final jpRows = await _client.from('job_parts').select().eq('job_id', jobId);
    final jobParts = (jpRows as List)
        .map((r) => JobPart.fromJson(_mapJobPartRow(r as Map)))
        .toList();
    for (final jp in jobParts) {
      final partId = jp.partId.trim();
      if (partId.isEmpty || jp.qty <= 0) continue;
      partQtyById[partId] = (partQtyById[partId] ?? 0) + jp.qty;
    }
    if (serviceSubtypeId != null && serviceSubtypeId.isNotEmpty) {
      try {
        final defaultRows = await _client
            .from('service_subtype_parts')
            .select('part_id, qty, is_optional')
            .eq('service_subtype_id', serviceSubtypeId)
            .eq('is_optional', false);
        for (final raw in (defaultRows as List)) {
          final row = (raw as Map).cast<String, Object?>();
          final partId = row['part_id']?.toString().trim() ?? '';
          final qty = (row['qty'] as num?)?.toInt() ?? 0;
          if (partId.isEmpty || qty <= 0) continue;
          partQtyById.putIfAbsent(partId, () => qty);
        }
      } catch (_) {}
    }
    if (partQtyById.isNotEmpty) {
      final pRows = await _client
          .from('parts')
          .select()
          .inFilter('id', partQtyById.keys.toList());
      final parts = (pRows as List)
          .map((r) => Part.fromJson(_mapPartRow(r as Map)))
          .toList();
      final partById = {for (final p in parts) p.id: p};

      final inserts = <Map<String, Object?>>[];
      for (final entry in partQtyById.entries) {
        final part = partById[entry.key];
        if (part == null) continue;
        final qty = entry.value;
        final unit = part.sellPrice;
        final lt = (qty * unit).toDouble();
        inserts.add({
          'invoice_id': invoiceId,
          'type': 'part',
          'description': '${part.name} (${part.sku})',
          'qty': qty,
          'unit_price': part.sellPrice,
          'line_total': lt,
          'part_id': part.id,
        });
      }
      if (inserts.isNotEmpty) {
        await _client.from('invoice_items').insert(inserts);
      }
    }

    final serviceRows = await _client
        .from('invoice_items')
        .select('id, description, unit_price')
        .eq('invoice_id', invoiceId)
        .eq('type', 'service');
    final list = (serviceRows as List)
        .map((r) => (r as Map).cast<String, Object?>())
        .toList();
    final hasManualPriced = list.any((r) {
      final d = r['description']?.toString() ?? '';
      final u = (r['unit_price'] as num?) ?? 0;
      if (u <= 0) return false;
      if (d == 'Jasa Servis') return false;
      if (d.startsWith('Jasa -')) return false;
      return true;
    });
    if (!hasManualPriced) {
      String? targetId;
      for (final r in list) {
        final id = r['id']?.toString() ?? '';
        final d = r['description']?.toString() ?? '';
        if (id.isEmpty) continue;
        if (d == serviceDesc || d == 'Jasa Servis' || d.startsWith('Jasa -')) {
          targetId = id;
          break;
        }
      }
      final lt = serviceUnitPrice.toDouble();
      if (targetId != null) {
        await _client
            .from('invoice_items')
            .update({
              'description': serviceDesc,
              'qty': 1,
              'unit_price': serviceUnitPrice,
              'line_total': lt,
            })
            .eq('id', targetId);
      } else {
        await _client.from('invoice_items').insert({
          'invoice_id': invoiceId,
          'type': 'service',
          'description': serviceDesc,
          'qty': 1,
          'unit_price': serviceUnitPrice,
          'line_total': lt,
        });
      }
    }

    return recomputeInvoiceTotals(invoiceId: invoiceId);
  }

  Future<void> addServiceItem({
    required String invoiceId,
    required String description,
    required int qty,
    required num unitPrice,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin && actor.role != AppRole.kasir) {
      throw Exception('forbidden');
    }
    if (qty <= 0) throw Exception('qty_invalid');
    if (description.trim().isEmpty) throw Exception('description_invalid');
    final lt = (qty * unitPrice).toDouble();
    await _client.from('invoice_items').insert({
      'invoice_id': invoiceId,
      'type': 'service',
      'description': description,
      'qty': qty,
      'unit_price': unitPrice,
      'line_total': lt,
    });
    await recomputeInvoiceTotals(invoiceId: invoiceId);
  }

  Future<InvoiceSummary> recomputeInvoiceTotals({
    required String invoiceId,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin && actor.role != AppRole.kasir) {
      throw Exception('forbidden');
    }

    final invRow = await _client
        .from('invoices')
        .select('id, discount')
        .eq('id', invoiceId)
        .single();
    final discount = (invRow['discount'] as num?) ?? 0;

    final itemRows = await _client
        .from('invoice_items')
        .select('id, qty, unit_price, line_total')
        .eq('invoice_id', invoiceId);

    num subtotal = 0;
    final fixes = <Future<void>>[];
    for (final raw in (itemRows as List)) {
      final r = (raw as Map).cast<String, Object?>();
      final id = r['id']?.toString() ?? '';
      final qty = (r['qty'] as num?)?.toInt() ?? 0;
      final unit = (r['unit_price'] as num?) ?? 0;
      final expected = qty * unit;
      subtotal += expected;
      final current = (r['line_total'] as num?);
      if (id.isNotEmpty && (current == null || current != expected)) {
        fixes.add(
          _client
              .from('invoice_items')
              .update({'line_total': expected})
              .eq('id', id)
              .then((_) {}),
        );
      }
    }
    if (fixes.isNotEmpty) {
      await Future.wait(fixes);
    }

    final total = (subtotal - discount).clamp(0, 999999999999);
    await _client
        .from('invoices')
        .update({'subtotal': subtotal, 'total': total})
        .eq('id', invoiceId);

    await _refreshInvoices();
    notifyListeners();
    return _invoices.firstWhere((s) => s.invoice.id == invoiceId);
  }

  Future<InvoiceSummary> finalizeInvoice({required String invoiceId}) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin && actor.role != AppRole.kasir) {
      throw Exception('forbidden');
    }

    final before = await recomputeInvoiceTotals(invoiceId: invoiceId);
    if (before.items.isEmpty) throw Exception('invoice_items_empty');
    if (before.invoice.total <= 0) throw Exception('invoice_total_invalid');

    final already = await _client
        .from('stock_movements')
        .select('id')
        .eq('ref_type', 'invoice')
        .eq('ref_id', invoiceId)
        .maybeSingle();
    await _client
        .from('invoices')
        .update({
          'status': 'final',
          'finalized_by': actor.userId,
          'finalized_at': DateTime.now().toIso8601String(),
        })
        .eq('id', invoiceId);

    if (already == null) {
      final itemRows = await _client
          .from('invoice_items')
          .select()
          .eq('invoice_id', invoiceId)
          .eq('type', 'part');
      final partItems = (itemRows as List)
          .map((r) => InvoiceItem.fromJson((r as Map).cast<String, Object?>()))
          .toList();
      for (final it in partItems) {
        final partId = it.partId;
        if (partId == null || partId.isEmpty) continue;
        final current = await _client
            .from('parts')
            .select('stock_on_hand')
            .eq('id', partId)
            .single();
        final currentQty = (current['stock_on_hand'] as num?)?.toInt() ?? 0;
        if (currentQty < it.qty) {
          throw Exception('stok_tidak_cukup');
        }
        await _client
            .from('parts')
            .update({'stock_on_hand': currentQty - it.qty})
            .eq('id', partId);
        await _client.from('stock_movements').insert({
          'part_id': partId,
          'type': 'out',
          'qty': it.qty,
          'note': 'Keluar karena invoice final',
          'ref_type': 'invoice',
          'ref_id': invoiceId,
          'created_by': actor.userId,
        });
      }
      await _refreshParts();
    }

    await _refreshInvoices();
    notifyListeners();
    return _invoices.firstWhere((s) => s.invoice.id == invoiceId);
  }

  Future<InvoiceSummary> setInvoiceRequestedPaymentMethod({
    required String invoiceId,
    required PaymentMethod method,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.admin) throw Exception('forbidden');
    await _client
        .from('invoices')
        .update({'requested_payment_method': method.name})
        .eq('id', invoiceId);
    await _refreshInvoices();
    notifyListeners();
    return _invoices.firstWhere((s) => s.invoice.id == invoiceId);
  }

  Future<InvoicePayment> payCash({
    required String invoiceId,
    required num amount,
    num? cashReceived,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.kasir) throw Exception('forbidden');
    final inv = await _client
        .from('invoices')
        .select('status, total')
        .eq('id', invoiceId)
        .single();
    final status = inv['status']?.toString() ?? 'draft';
    final total = (inv['total'] as num?) ?? 0;
    if (status != 'final' && status != 'draft')
      throw Exception('invoice_belum_final');
    if (total <= 0) throw Exception('invoice_total_invalid');
    final payAmount = amount <= 0 ? total : amount;
    final received = cashReceived == null || cashReceived <= 0
        ? payAmount
        : cashReceived;
    final change = received > payAmount ? (received - payAmount) : 0;
    final row = await _client
        .from('payments')
        .insert({
          'invoice_id': invoiceId,
          'method': 'cash',
          'status': 'paid',
          'amount': payAmount,
          'cash_received': received,
          'cash_change': change,
          'paid_at': DateTime.now().toIso8601String(),
          'created_by': actor.userId,
          'verified_by': actor.userId,
          'verified_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    final pay = InvoicePayment.fromJson(
      _mapPaymentRow((row as Map).cast<String, Object?>()),
    );
    await _refreshInvoices();
    notifyListeners();
    return pay;
  }

  Future<InvoicePayment> submitTransfer({
    required String invoiceId,
    required num amount,
    required String transferRef,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    final inv = await _client
        .from('invoices')
        .select('status, total')
        .eq('id', invoiceId)
        .single();
    final status = inv['status']?.toString() ?? 'draft';
    final total = (inv['total'] as num?) ?? 0;
    if (status != 'final' && status != 'draft')
      throw Exception('invoice_belum_final');
    if (total <= 0) throw Exception('invoice_total_invalid');
    final row = await _client
        .from('payments')
        .insert({
          'invoice_id': invoiceId,
          'method': 'transfer',
          'status': 'pending',
          'amount': amount <= 0 ? total : amount,
          'transfer_ref': transferRef,
          'created_by': actor.userId,
        })
        .select()
        .single();
    final pay = InvoicePayment.fromJson(
      _mapPaymentRow((row as Map).cast<String, Object?>()),
    );
    await _refreshInvoices();
    notifyListeners();
    return pay;
  }

  String paymentProofUrl({required String proofPath}) {
    return _client.storage.from('payment_proofs').getPublicUrl(proofPath);
  }

  Future<InvoicePayment> submitTransferWithProof({
    required String invoiceId,
    required num amount,
    required String transferRef,
    required Uint8List proofBytes,
    required String proofFilename,
    required String proofMime,
    String? accountId,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    final inv = await _client
        .from('invoices')
        .select('status, total')
        .eq('id', invoiceId)
        .single();
    final status = inv['status']?.toString() ?? 'draft';
    final total = (inv['total'] as num?) ?? 0;
    if (status != 'final' && status != 'draft')
      throw Exception('invoice_belum_final');
    if (total <= 0) throw Exception('invoice_total_invalid');

    final safeName = proofFilename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final path = '${actor.userId}/$invoiceId/${nowMs}_$safeName';

    await _client.storage
        .from('payment_proofs')
        .uploadBinary(
          path,
          proofBytes,
          fileOptions: FileOptions(contentType: proofMime, upsert: false),
        );

    dynamic row;
    try {
      row = await _client
          .from('payments')
          .insert({
            'invoice_id': invoiceId,
            'method': 'transfer',
            'status': 'pending',
            'amount': amount <= 0 ? total : amount,
            'transfer_ref': transferRef,
            'proof_path': path,
            'proof_mime': proofMime,
            'account_id': accountId,
            'created_by': actor.userId,
          })
          .select()
          .single();
    } catch (e) {
      try {
        await _client.storage.from('payment_proofs').remove([path]);
      } catch (_) {}
      rethrow;
    }

    final pay = InvoicePayment.fromJson(
      _mapPaymentRow((row as Map).cast<String, Object?>()),
    );
    await _refreshInvoices();
    notifyListeners();
    return pay;
  }

  Future<InvoicePayment> verifyTransfer({
    required String paymentId,
    required bool approve,
  }) async {
    final actor = _profile;
    if (actor == null) throw Exception('not_authenticated');
    if (actor.role != AppRole.kasir) throw Exception('forbidden');
    final patch = <String, Object?>{
      'status': approve ? 'paid' : 'rejected',
      'verified_by': actor.userId,
      'verified_at': DateTime.now().toIso8601String(),
      if (approve) 'paid_at': DateTime.now().toIso8601String(),
    };
    final row = await _client
        .from('payments')
        .update(patch)
        .eq('id', paymentId)
        .select()
        .single();
    final pay = InvoicePayment.fromJson(
      _mapPaymentRow((row as Map).cast<String, Object?>()),
    );
    await _refreshInvoices();
    notifyListeners();
    return pay;
  }
}

int _msFromTs(Object? v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is DateTime) return v.millisecondsSinceEpoch;
  final s = v.toString();
  if (s.isEmpty) return 0;
  return DateTime.parse(s).millisecondsSinceEpoch;
}

String _toDateString(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

String _bookingStatusToDb(BookingStatus s) {
  return switch (s) {
    BookingStatus.pending => 'pending',
    BookingStatus.confirmed => 'confirmed',
    BookingStatus.rejected => 'rejected',
    BookingStatus.checkedIn => 'checked_in',
    BookingStatus.cancelled => 'cancelled',
    BookingStatus.done => 'done',
  };
}

String _bookingStatusFromDb(String s) {
  return switch (s) {
    'checked_in' => BookingStatus.checkedIn.name,
    _ => s,
  };
}

String _jobStatusToDb(JobStatus s) {
  return switch (s) {
    JobStatus.inProgress => 'in_progress',
    _ => s.name,
  };
}

String _jobStatusFromDb(String s) {
  return switch (s) {
    'in_progress' => JobStatus.inProgress.name,
    _ => s,
  };
}

String _invoiceStatusFromDb(String s) {
  return switch (s) {
    'final' => InvoiceStatus.finalStatus.name,
    'void' => InvoiceStatus.voidStatus.name,
    _ => s,
  };
}

String _paymentStatusFromDb(String s) {
  return switch (s) {
    'pending' => PaymentStatus.pending.name,
    'paid' => PaymentStatus.paid.name,
    'rejected' => PaymentStatus.rejected.name,
    _ => PaymentStatus.unpaid.name,
  };
}

Map<String, Object?> _mapVehicleRow(Map<dynamic, dynamic> r) {
  return <String, Object?>{
    'id': r['id']?.toString() ?? '',
    'customer_id': r['customer_id']?.toString() ?? '',
    'plate_number': r['plate_number']?.toString() ?? '',
    'brand': r['brand']?.toString() ?? '',
    'model': r['model']?.toString() ?? '',
    'created_at_ms': _msFromTs(r['created_at']),
  };
}

Map<String, Object?> _mapBookingRow(Map<dynamic, dynamic> r) {
  final statusDb = r['status']?.toString() ?? 'pending';
  return <String, Object?>{
    'id': r['id']?.toString() ?? '',
    'customer_id': r['customer_id']?.toString() ?? '',
    'vehicle_id': r['vehicle_id']?.toString(),
    'booking_date':
        r['booking_date']?.toString() ?? DateTime.now().toIso8601String(),
    'booking_time': r['booking_time']?.toString() ?? '08:00',
    'complaint': r['complaint']?.toString() ?? '',
    'status': _bookingStatusFromDb(statusDb),
    'type': r['type']?.toString() ?? 'service',
    'service_type_id': r['service_type_id']?.toString(),
    'service_subtype_id': r['service_subtype_id']?.toString(),
    'modif_payload': (r['modif_payload'] as Map?)?.cast<String, Object?>(),
    'created_at_ms': _msFromTs(r['created_at']),
    'confirmed_by': r['confirmed_by']?.toString(),
    'confirmed_at_ms': r['confirmed_at'] == null
        ? null
        : _msFromTs(r['confirmed_at']),
  };
}

Map<String, Object?> _mapPartRow(Map<dynamic, dynamic> r) {
  return <String, Object?>{
    'id': r['id']?.toString() ?? '',
    'sku': r['sku']?.toString() ?? '',
    'name': r['name']?.toString() ?? '',
    'unit': r['unit']?.toString() ?? 'pcs',
    'sell_price': (r['sell_price'] as num?) ?? 0,
    'buy_price': (r['buy_price'] as num?) ?? 0,
    'stock_on_hand': (r['stock_on_hand'] as num?)?.toInt() ?? 0,
    'min_stock': (r['min_stock'] as num?)?.toInt() ?? 0,
    'is_active': (r['is_active'] as bool?) ?? true,
    'created_at_ms': _msFromTs(r['created_at']),
  };
}

Map<String, Object?> _mapJobRow(Map<dynamic, dynamic> r) {
  final s = _jobStatusFromDb(r['status']?.toString() ?? 'draft');
  return <String, Object?>{
    'id': r['id']?.toString() ?? '',
    'customer_id': r['customer_id']?.toString() ?? '',
    'vehicle_id': r['vehicle_id']?.toString(),
    'complaint': r['complaint']?.toString() ?? '',
    'status': s,
    'created_by': '',
    'created_at_ms': _msFromTs(r['created_at']),
    'booking_id': r['booking_id']?.toString(),
    'assigned_mechanic_id': r['assigned_mechanic_id']?.toString(),
    'note': r['note']?.toString(),
    'priority': r['priority']?.toString(),
    'eta_minutes': (r['eta_minutes'] as num?)?.toInt(),
    'service_actions': (r['service_actions'] as List?)?.cast<Object?>(),
  };
}

Map<String, Object?> _mapJobPartRow(Map<dynamic, dynamic> r) {
  return <String, Object?>{
    'id': r['id']?.toString() ?? '',
    'job_id': r['job_id']?.toString() ?? '',
    'part_id': r['part_id']?.toString() ?? '',
    'qty': (r['qty'] as num?)?.toInt() ?? 0,
    'created_by': '',
    'created_at_ms': _msFromTs(r['created_at']),
  };
}

Map<String, Object?> _mapInvoiceRow(Map<dynamic, dynamic> r) {
  final s = _invoiceStatusFromDb(r['status']?.toString() ?? 'draft');
  return <String, Object?>{
    'id': r['id']?.toString() ?? '',
    'job_id': r['job_id']?.toString() ?? '',
    'status': s,
    'subtotal': (r['subtotal'] as num?) ?? 0,
    'discount': (r['discount'] as num?) ?? 0,
    'total': (r['total'] as num?) ?? 0,
    'created_by': '',
    'created_at_ms': _msFromTs(r['created_at']),
    'finalized_by': r['finalized_by']?.toString(),
    'finalized_at_ms': r['finalized_at'] == null
        ? null
        : _msFromTs(r['finalized_at']),
    'requested_payment_method': r['requested_payment_method']?.toString(),
  };
}

Map<String, Object?> _mapPaymentRow(Map<dynamic, dynamic> r) {
  final s = _paymentStatusFromDb(r['status']?.toString() ?? '');
  return <String, Object?>{
    'id': r['id']?.toString() ?? '',
    'invoice_id': r['invoice_id']?.toString() ?? '',
    'method': r['method']?.toString() ?? 'cash',
    'status': s,
    'amount': (r['amount'] as num?) ?? 0,
    'created_by': r['created_by']?.toString() ?? '',
    'created_at_ms': _msFromTs(r['created_at']),
    'transfer_ref': r['transfer_ref']?.toString(),
    'proof_note': r['proof_note']?.toString(),
    'proof_path': r['proof_path']?.toString(),
    'proof_mime': r['proof_mime']?.toString(),
    'account_id': r['account_id']?.toString(),
    'cash_received': r['cash_received'] as num?,
    'cash_change': r['cash_change'] as num?,
    'verified_by': r['verified_by']?.toString(),
    'verified_at_ms': r['verified_at'] == null
        ? null
        : _msFromTs(r['verified_at']),
    'paid_at_ms': r['paid_at'] == null ? null : _msFromTs(r['paid_at']),
  };
}

Map<String, Object?> _mapStockMovementRow(Map<dynamic, dynamic> r) {
  return <String, Object?>{
    'id': r['id']?.toString() ?? '',
    'part_id': r['part_id']?.toString() ?? '',
    'type': r['type']?.toString() ?? 'in',
    'qty': (r['qty'] as num?)?.toInt() ?? 0,
    'note': r['note']?.toString() ?? '',
    'ref_type': r['ref_type']?.toString() ?? '',
    'ref_id': r['ref_id']?.toString(),
    'created_by': r['created_by']?.toString() ?? '',
    'created_at_ms': _msFromTs(r['created_at']),
  };
}

Map<String, Object?> _mapAttendanceRow(Map<dynamic, dynamic> r) {
  return <String, Object?>{
    'id': r['id']?.toString() ?? '',
    'staff_id': r['staff_id']?.toString() ?? '',
    'work_date': r['work_date']?.toString() ?? _toDateString(DateTime.now()),
    'check_in_ms': _msFromTs(r['check_in']),
    'break_start_ms': r['break_start'] == null
        ? null
        : _msFromTs(r['break_start']),
    'break_end_ms': r['break_end'] == null ? null : _msFromTs(r['break_end']),
    'check_out_ms': r['check_out'] == null ? null : _msFromTs(r['check_out']),
    'auto_checkout': (r['auto_checkout'] as bool?) ?? false,
    'created_at_ms': _msFromTs(r['created_at']),
  };
}
