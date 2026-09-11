# ==========================================
# Tahap 1: Build Flutter Web (Multi-stage)
# ==========================================
FROM ghcr.io/cirruslabs/flutter:3.35.4 AS build-stage

WORKDIR /app

# Salin dependencies untuk efisiensi Docker layer cache
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Salin source code aplikasi
COPY . .

# Konfigurasi Supabase via Dart Defines (bisa di-override saat build)
ARG SUPABASE_URL="https://pmspsgjhndvyzwojhssz.supabase.co"
ARG SUPABASE_ANON_KEY="sb_publishable_fVfdx-dLYWMJy_3i_b9L4A_rYQ5ETSI"

# Kompilasi Flutter Web ke mode release
RUN flutter build web --release \
    --dart-define=SUPABASE_URL=${SUPABASE_URL} \
    --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}

# ==========================================
# Tahap 2: Serving Production dengan Nginx
# ==========================================
FROM nginx:alpine

# Pasang konfigurasi Nginx SPA
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Salin file statis Flutter Web dari build stage
COPY --from=build-stage /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
