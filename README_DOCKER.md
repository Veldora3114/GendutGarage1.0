# Panduan Menjalankan Docker - Gendut Garage Web

Aplikasi **Gendut Garage** adalah aplikasi Flutter yang mendukung platform Web dan terhubung dengan backend Supabase. Konfigurasi Docker ini membungkus aplikasi Flutter Web ke dalam web server **Nginx (Alpine)** yang sangat ringan, cepat, dan aman.

---

## 📋 Prasyarat

1. **Docker & Docker Desktop**: Pastikan Docker Desktop sudah terpasang dan berjalan di laptop/komputer Anda ([Unduh Docker Desktop](https://www.docker.com/products/docker-desktop/)).
2. Jika menggunakan **Metode 2 (Build Cepat)**, pastikan Flutter SDK sudah terpasang (sudah terverifikasi di laptop Anda: Flutter 3.35.4).

---

## 🚀 Pilihan Cara Menjalankan

Tersedia 2 pilihan metode:

### Metode 1: Menggunakan Docker Compose (Multi-Stage Build Otomatis)
*Seluruh proses kompilasi Flutter dilakukan otomatis di dalam Docker container tanpa perlu menyentuh file lokal.*

1. Buka terminal (PowerShell / Command Prompt) di folder `GendutGarage1.0`:
   ```bash
   cd "c:\Users\Raiha\Downloads\skripsi_raihan\GendutGarage1.0"
   ```

2. Jalankan build dan nyalakan container:
   ```bash
   docker compose up -d --build
   ```

3. Buka browser dan akses aplikasi di:
   ```text
   http://localhost:8080
   ```

4. Untuk menghentikan container:
   ```bash
   docker compose down
   ```

---

### Metode 2: Build Cepat Lokal (Sangat Direkomendasikan untuk Hemat Waktu & Kuota)
*Karena laptop Anda sudah memiliki Flutter 3.35.4, build lokal jauh lebih cepat (hanya ~30 detik) dibanding mengunduh image Flutter SDK Linux di Docker.*

1. Lakukan kompilasi web secara lokal terlebih dahulu:
   ```bash
   flutter build web --release
   ```

2. Build image Docker menggunakan `Dockerfile.quick`:
   ```bash
   docker build -t gendut-garage:latest -f Dockerfile.quick .
   ```

3. Jalankan container:
   ```bash
   docker run -d -p 8080:80 --name gendut_garage_web gendut-garage:latest
   ```

4. Buka di browser:
   ```text
   http://localhost:8080
   ```

---

## 📁 Penjelasan File Konfigurasi

* **[`Dockerfile`](./Dockerfile)**: Menggunakan pendekatan *multi-stage build*. Tahap 1 mengompilasi Flutter Web menggunakan Flutter SDK image, tahap 2 memindahkan hasil kompilasi ke Nginx Alpine image.
* **[`Dockerfile.quick`](./Dockerfile.quick)**: Dockerfile minimalis yang langsung menyalin folder `build/web` lokal ke Nginx Alpine (ukuran image hanya ~20-30 MB).
* **[`nginx.conf`](./nginx.conf)**: Konfigurasi Nginx dengan Single Page Application (SPA) fallback (`try_files $uri $uri/ /index.html;`) agar navigasi halaman web tidak menghasilkan *Error 404* saat di-refresh, ditambah kompresi Gzip.
* **[`docker-compose.yml`](./docker-compose.yml)**: Konfigurasi orkestrasi untuk menjalankan container dengan satu perintah `docker compose up -d`.
* **[`.dockerignore`](./.dockerignore)**: Mengabaikan folder Android, iOS, Windows, git, dan dokumen skripsi agar proses build Docker menjadi sangat cepat dan efisien.
