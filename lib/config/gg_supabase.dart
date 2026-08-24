class GGSupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pmspsgjhndvyzwojhssz.supabase.co',
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_fVfdx-dLYWMJy_3i_b9L4A_rYQ5ETSI',
  );
  static const gmapsReviewUrl = String.fromEnvironment(
    'GMAPS_REVIEW_URL',
    defaultValue:
        'https://www.google.com/maps/place/Gendut+garage/@-6.4565179,106.744702,17z/data=!4m8!3m7!1s0x2e69e900522ec893:0x5edcdcd3ca360deb!8m2!3d-6.4565179!4d106.7472769!9m1!1b1!16s%2Fg%2F11wxgyrwj2?entry=ttu&g_ep=EgoyMDI2MDUyNy4wIKXMDSoASAFQAw%3D%3D',
  );

  static bool get isConfigured {
    return url.isNotEmpty && anonKey.isNotEmpty;
  }
}
