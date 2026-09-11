# 🏎️ Gendut Garage (GendutGarage 1.0)
Sistem Informasi Manajemen Bengkel Berbasis **Flutter Web** & **Supabase Backend**.

---

# 🐳 Docker untuk Anak Kampus — Satu PC Lab, 40 Mahasiswa, Nol Bentrok
### *(Panduan Instalasi & Deploy di Komputer Lab Bersama Tanpa Error)*

> **"Di laptop saya jalan kok, Pak!"**  
> Kalimat keramat yang paling sering bikin dosen penguji mengernyitkan dahi. Sekarang, dengan Docker, kalimat itu resmi pensiun karena kamu membawa "laptop"-nya sekalian ke PC lab.

---

Ada satu PC lab kampus. Ada 40-an mahasiswa tingkat akhir yang antre harus instal aplikasi skripsi di situ buat penilaian atau demo. 

Coba bayangkan kalau semuanya instal manual:
* Kamu butuh **Flutter 3.35**, teman sebelah butuh **Flutter 3.19** karena dependensi lamanya belum dukung Dart 3.
* Teman yang lain butuh **Node 18**, ada yang butuh **Node 22**, ada yang pasang **XAMPP / PHP 7.4**, ada yang butuh **Python 3.11**.
* Satu orang gonta-ganti *Environment Variables (PATH)* atau instal ulang SDK di PC lab, tiga skripsi mahasiswa lain langsung mati total.
* Belum lagi waktu instalasinya: unduh Flutter SDK 1.5 GB, unduh Chrome driver, jalankan `pub get`, tunggu kompilasi. Satu orang habis 45 menit kalau lancar. Kali 40 orang? Itu hampir 30 jam, dan lab kampus keburu tutup.

Docker menyelesaikan masalah itu dalam satu pukulan telak. Panduan ini dibuat khusus untuk memandu kamu memasang aplikasi **Gendut Garage** di PC lab kampus tanpa bentrok, tanpa ribet, dan selesai dalam hitungan detik.

---

## ⚡ Buru-buru? 4 Perintah Ini Dulu

Kalau di PC lab komputer sudah ada Docker dan kamu sudah bawa berkasnya, cukup jalankan ini di terminal lab:

```bash
# 1. Masuk ke folder proyekmu di PC lab
cd "D:\SKRIPSI_MAHASISWA\RAIHAN\GendutGarage1.0"

# 2. Nyalakan dengan nama proyekmu sendiri (pakai nama/NIM)
docker compose -p raihan up -d

# 3. Cek apakah aplikasinya hidup normal
docker compose -p raihan ps

# 4. Kalau sudah selesai demo di depan dosen, matikan dengan rapi
docker compose -p raihan down
```

> **Ingat:** Ganti `raihan` dengan nama atau NIM kamu, dan pastikan port di `docker-compose.yml` tidak kembar dengan teman yang sedang jalan barengan.

---

## 🍱 Docker Itu Apa Sih? (Analogi Warung Makan)

Bayangkan kamu pesan makanan lewat ojek online. Kamu tidak perlu tahu dapurnya restoran itu pakai kompor gas melon atau kompor induksi, wajannya merek apa, atau kencurnya beli di pasar mana. Makanannya datang dalam **kotak tertutup yang higienis, siap santap**, dan rasanya sama persis di mana pun kamu membukanya.

**Docker melakukan hal yang sama untuk aplikasi skripsimu:**  
Aplikasi Flutter Web kamu dibungkus bersama web server Nginx, konfigurasi routing, dan dependensinya ke dalam satu kotak tertutup bernama **Container**. Kotak itu dijamin jalan sama persis di laptop Asus kamu, laptop Macbook dosen, maupun PC lab kampus ber-Windows jadul.

### 3 Kata yang Wajib Kamu Bedakan

| Kata | Analoginya | Sifatnya |
| :--- | :--- | :--- |
| **Image** | Resep + bahan mentah yang sudah dibelanjakan | Diam, *read-only*, bisa disimpan dan dibagikan. |
| **Container** | Masakan yang sedang tersaji di meja dan dimakan | Hidup, berjalan, bisa dimatikan atau dihapus. |
| **Volume** | Kulkas / Lemari penyimpanan | Datanya tetap awet walau wadah masakannya dibuang. |

---

## ⚙️ Cara Kerjanya di Gendut Garage: 2 Berkas Sakti

Di proyek `GendutGarage1.0`, kita sudah menyiapkan dua berkas utama:

### 1. `Dockerfile` — Resep Masakan
Berkas ini menjawab: *"Aplikasi Flutter ini butuh apa saja supaya bisa disajikan?"*

Kita menggunakan teknik **Multi-Stage Build** (standar industri):
```dockerfile
# TAHAP 1: DAPUR (Build Stage)
# Pakai image resmi Flutter untuk kompilasi kode
FROM ghcr.io/cirruslabs/flutter:3.35.4 AS build-stage
WORKDIR /app

# Trik caching: salin file dependencies dulu biar tidak download ulang tiap saat
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Baru salin kodenya dan kompilasi ke web
COPY . .
RUN flutter build web --release

# TAHAP 2: MEJA SAJI (Production Stage)
# Pakai Nginx Alpine super ringan (~25 MB)
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build-stage /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```
**Kenapa dibagi 2 tahap?**  
Karena Flutter SDK itu berat (1.5 GB). Komputer lab tidak butuh Flutter SDK untuk menjalankan aplikasi web! Jadi di Tahap 2, kita hanya mengambil folder `build/web`-nya saja lalu ditempel ke Nginx. Hasil akhirnya kontainer jadi mungil, enteng, dan hemat RAM lab.

### 2. `nginx.conf` — Pengatur Lalu Lintas Single Page App (SPA)
Flutter Web itu aplikasi satu halaman (SPA). Kalau kamu membuka menu `/login` lalu me-refresh browser, tanpa konfigurasi yang benar web server akan bingung dan memunculkan **Error 404 Not Found**.

Baris sakti di `nginx.conf` ini yang menyelamatkan skripsimu:
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```
Artinya: *"Nginx, kalau ada rute halaman yang tidak berupa file fisik, jangan kasih 404! Arahkan ke `index.html` biar Flutter yang menampilkan halamannya."*

---

## 🚦 Aturan Main di PC Lab yang Dipakai Bareng (Wajib Tahu!)

Ini bagian paling krusial. 90% kegagalan di lab kampus terjadi bukan karena kodingannya salah, tapi karena bentrok dengan mahasiswa lain.

### 1. Aturan Nomor Port: Gunakan 2 Digit Terakhir NIM
Satu komputer tidak bisa membuka port yang sama untuk dua orang sekaligus. Kalau temanmu sudah memakai port `8080:80` dan kamu nekat menyalakan `8080:80`, punyamu akan langsung mental dengan tulisan:  
`Error: port is already allocated`.

**Solusi Cerdas:**  
Pakai formula **80 + [2 Digit Terakhir NIM]**.  
Misalkan NIM kamu berakhiran **14**:  
Buka `docker-compose.yml`, ubah menjadi:
```yaml
ports:
  - "8014:80"
```
Aplikasi kamu sekarang bisa diakses di `http://localhost:8014`, dan temanmu yang NIM-nya 25 bisa jalan barengan di `http://localhost:8025` di PC yang sama tanpa bentrok!

### 2. Beri Nama Proyek Sendiri dengan Flag `-p`
Jangan pernah cuma ketik `docker compose up -d` di komputer lab bersama. Kalau kamu dan temanmu sama-sama menjalankan perintah itu, container temanmu bisa tertimpa atau error bentrok nama.

Selalu sertakan nama/NIM kamu:
```bash
docker compose -p raihan up -d
```
Docker akan memberi awalan `raihan_` ke semua container dan jaringannya secara otomatis.

### 3. Bereskan Setelah Selesai Dinilai Dosen!
Kalau sesi demo sudah selesai, bersihkan komputer lab agar adik tingkat atau teman berikutnya bisa pakai:
```bash
docker compose -p raihan down
```

---

## 🏗️ Alur Eksekusi: 2 Jalur Masuk ke Lab Kampus

Jangan pernah melakukan kompilasi (`flutter build`) dari nol di PC lab kalau tidak terpaksa. Lakukan kompilasi di tempat lain, bawa barang jadi ke lab!

```
[ Laptop Kamu ]                      [ PC Lab Kampus ]
flutter build web               
docker build (Dockerfile.quick) ──Flashdisk──> docker load -i gendut-garage.tar
docker save (.tar ~25MB)                       docker run -d -p 8014:80 ...
```

### Jalur A: Ekspor File `.tar` Pakai Flashdisk (Paling Disukai Dosen, 100% Offline)

Jalur ini sangat aman kalau lab kampus internetnya lambat atau diblokir.

1. **Di Laptop Kamu:**
   Pastikan Docker Desktop sudah jalan, lalu buka terminal proyek:
   ```powershell
   # 1. Build web lokal (cepat karena Flutter sudah ada di laptop)
   flutter build web --release

   # 2. Bungkus ke Docker image
   docker build -t gendut-garage:v1 -f Dockerfile.quick .

   # 3. Simpan jadi satu file tar kecil (~25-30 MB)
   docker save -o gendut-garage.tar gendut-garage:v1
   ```
2. **Copy file `gendut-garage.tar` ke Flashdisk.**
3. **Di PC Lab Kampus:**
   Colok flashdisk, buka Command Prompt / PowerShell di lab:
   ```bash
   # Load image ke Docker lab
   docker load -i gendut-garage.tar

   # Jalankan kontainernya
   docker run -d -p 8014:80 --name gendut_raihan gendut-garage:v1
   ```
4. Buka browser: `http://localhost:8014`. **Selesai dalam 10 detik!**

---

### Jalur B: Menggunakan GitHub Actions (Bagi yang Laptopnya Lemah / RAM Pas-pasan)

Jika laptop kamu RAM-nya pas-pasan atau malas pasang Docker Desktop di laptop, biarkan **server gratisan milik GitHub** yang membuatkan Docker Image-nya untukmu!

File alur kerja sudah tersedia di `.github/workflows/docker-build.yml`.  
Tiap kamu klik **Push origin** di GitHub Desktop, GitHub akan otomatis mengompilasi dan mengunggah image ke Docker Hub.  
Di PC lab kampus, kamu tinggal ketik:
```bash
docker run -d -p 8014:80 username_kamu/gendut-garage:latest
```

---

## 🔧 Kamus Masalah: Kalau Error di PC Lab

| Pesan Error | Penyebabnya | Solusinya |
| :--- | :--- | :--- |
| `port is already allocated` | Port (misal 8080) sedang dipakai mahasiswa lain di PC tersebut. | Ganti angka port sebelah kiri di `docker-compose.yml` jadi `8014:80` (sesuaikan NIM). |
| `Cannot connect to the Docker daemon` | Docker Desktop di PC lab belum dibuka atau belum nyala. | Buka aplikasi Docker Desktop di Start Menu, tunggu ikon pojok kiri bawah jadi hijau *"Running"*. |
| `Conflict. The container name ... is already in use` | Ada container lama yang belum dimatikan atau namanya kembar. | Jalankan `docker rm -f nama_container` atau gunakan `-p namamu` saat compose up. |
| Layar putih / blank saat dibuka di browser | Path base href atau Supabase key salah. | Pastikan `base href="/"` di `index.html` dan koneksi internet lab mengizinkan akses ke host Supabase. |
| Web 404 saat tombol refresh diklik | Nginx belum diatur mode fallback SPA. | Pastikan baris `try_files $uri $uri/ /index.html;` ada di `nginx.conf`. |

---

## 📁 Struktur Berkas Terkait Docker di Proyek Ini

* **[`Dockerfile`](./Dockerfile)**: Multi-stage build (Flutter SDK -> Nginx Alpine).
* **[`Dockerfile.quick`](./Dockerfile.quick)**: Build instan memakai folder `build/web` lokal (~25MB).
* **[`nginx.conf`](./nginx.conf)**: Konfigurasi Nginx SPA fallback + Gzip.
* **[`docker-compose.yml`](./docker-compose.yml)**: Konfigurasi orkestrasi container.
* **[`.dockerignore`](./.dockerignore)**: Pengecualian berkas non-web untuk build kilat.
* **[`TUTORIAL_DOCKER_LAB.md`](./TUTORIAL_DOCKER_LAB.md)**: Salinan panduan tutorial lengkap.
