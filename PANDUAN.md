# 🚀 Panduan Deploy Paperclip di Railway
## Dengan Gemini sebagai AI Adapter Lokal
### Untuk Pemula | Step-by-Step Lengkap

---

## 📋 Daftar Isi
1. [Persiapan Awal](#persiapan)
2. [Struktur Proyek](#struktur)
3. [Setup GitHub](#github)
4. [Setup Railway](#railway)
5. [Setup Gemini API Key](#gemini)
6. [Deploy & Konfigurasi](#deploy)
7. [Troubleshooting](#troubleshoot)
8. [Cara Kerja Sistem](#arsitektur)

---

## LANGKAH 0 — Gambaran Besar

```
GitHub (kode) → Railway (server) → Docker (container)
                      ↓
              Gemini Adapter (lokal, gratis)
                      ↓
              Paperclip App (port 3000)
                      ↓
              PostgreSQL (database Railway)
```

**Yang kamu butuhkan:**
- Akun GitHub (gratis)
- Akun Railway (gratis)
- Akun Google (untuk Gemini API Key, gratis)
- Komputer dengan Git terinstall

---

## LANGKAH 1 — Persiapan Lokal

### 1.1 Install Git (jika belum ada)
```bash
# Windows: download dari https://git-scm.com
# Mac:
brew install git
# Ubuntu/Debian:
sudo apt install git
```

### 1.2 Clone template project ini
```bash
git clone https://github.com/irvanlaksana/paperclip-.git
cd paperclip-
```

### 1.3 Copy file-file dari folder ini ke root project
```
Salin file berikut ke root folder paperclip-:
├── Dockerfile          ← Resep build Docker
├── entrypoint.sh       ← Script startup
├── gemini-adapter.js   ← Adapter Gemini lokal
├── railway.toml        ← Konfigurasi Railway
├── .env.example        ← Template env variables
└── .gitignore          ← File yang dikecualikan dari Git
```

---

## LANGKAH 2 — Dapatkan Gemini API Key (GRATIS)

1. Buka → https://aistudio.google.com/app/apikey
2. Klik tombol **"Create API Key"**
3. Pilih project Google Cloud kamu (atau buat baru)
4. Copy API key yang muncul (contoh: `AIzaSy...`)
5. **Simpan di tempat aman** — akan dipakai di Railway nanti

> ✅ Gemini API Key GRATIS untuk penggunaan normal
> ✅ Model gemini-2.0-flash sangat cepat & hemat resource

---

## LANGKAH 3 — Push ke GitHub

```bash
# Di folder project kamu:

# 1. Init git jika belum
git init

# 2. Tambah semua file
git add .

# 3. Commit
git commit -m "Add Railway + Gemini adapter config"

# 4. Hubungkan ke GitHub repo kamu
git remote add origin https://github.com/irvanlaksana/paperclip-.git

# 5. Push
git push -u origin main
```

> ⚠️ PASTIKAN .env TIDAK ikut ter-push! Cek .gitignore sudah ada.

---

## LANGKAH 4 — Setup Railway

### 4.1 Buat akun Railway
1. Buka → https://railway.app
2. Klik **"Login"** → pilih **"Login with GitHub"**
3. Authorize Railway untuk akses GitHub

### 4.2 Buat proyek baru
1. Klik **"New Project"**
2. Pilih **"Deploy from GitHub repo"**
3. Cari dan pilih repo `paperclip-` milikmu
4. Railway akan mulai build otomatis (tunggu sebentar)

### 4.3 Tambah PostgreSQL Database
1. Di dashboard proyek, klik **"+ New"**
2. Pilih **"Database"** → **"Add PostgreSQL"**
3. Railway otomatis membuat database dan mengisi `DATABASE_URL`

---

## LANGKAH 5 — Set Environment Variables di Railway

1. Klik service **paperclip** di dashboard
2. Buka tab **"Variables"**
3. Klik **"RAW Editor"** (lebih mudah untuk paste banyak variabel)
4. Paste konfigurasi berikut (sesuaikan dengan nilai kamu):

```env
GEMINI_API_KEY=AIzaSy_GANTI_DENGAN_API_KEY_KAMU
AI_MODEL=gemini-2.0-flash
NEXTAUTH_SECRET=buat_random_string_panjang_di_sini_min_32_char
JWT_SECRET=buat_random_string_lain_di_sini_min_32_char
NODE_ENV=production
```

> 💡 Cara buat random string: buka terminal → ketik:
> ```bash
> openssl rand -hex 32
> ```
> Copy hasilnya untuk NEXTAUTH_SECRET dan JWT_SECRET

### 5.1 Set NEXTAUTH_URL setelah dapat domain
1. Setelah deploy berhasil, Railway memberikan URL seperti:
   `https://paperclip-production-abc123.up.railway.app`
2. Kembali ke Variables, tambahkan:
```env
NEXTAUTH_URL=https://paperclip-production-abc123.up.railway.app
NEXT_PUBLIC_APP_URL=https://paperclip-production-abc123.up.railway.app
```
3. Klik **"Deploy"** untuk apply perubahan

---

## LANGKAH 6 — Trigger Deploy

1. Railway biasanya auto-deploy setelah variables diset
2. Jika tidak, klik **"Deploy"** → **"Deploy Now"**
3. Pantau log di tab **"Deployments"** → klik deployment terbaru

**Log yang normal:**
```
[1/5] Memeriksa environment variables... ✓
[2/5] Menyiapkan direktori... ✓
[3/5] Memulai Gemini CLI adapter... ✓
[4/5] Menjalankan database migration... ✓
[5/5] Memulai Paperclip server...
     PORT: 3000
     AI Model: gemini-2.0-flash
```

---

## LANGKAH 7 — Verifikasi Deployment

### Cek health endpoint:
```
https://YOUR_APP.up.railway.app/health
```
Harus muncul: `{"status":"ok","adapter":"gemini",...}`

### Cek adapter lokal:
```
# Di log Railway, cari baris:
[Gemini Adapter] Berjalan di http://127.0.0.1:11434
[Gemini Adapter] API Key: ✓ Set
```

---

## TROUBLESHOOTING

### ❌ Error: "DATABASE_URL belum di-set"
→ Pastikan sudah tambah PostgreSQL plugin di Railway

### ❌ Error: "Cannot find module"
→ Cek apakah Dockerfile berhasil clone repo Paperclip
→ Lihat build logs di Railway

### ❌ Error: Out of Memory
→ Node.js sudah dibatasi 350MB via `--max-old-space-size=350`
→ Jika masih OOM, coba kurangi ke 300:
   Edit entrypoint.sh baris terakhir: `--max-old-space-size=300`

### ❌ Error: "Gemini adapter not responding"
→ Cek GEMINI_API_KEY sudah diset dengan benar
→ Pastikan tidak ada spasi atau karakter aneh

### ❌ App lambat / restart terus
→ Ini normal untuk Railway free tier
→ Aktifkan "Sleep" prevention dengan uptime monitor gratis:
   Gunakan https://uptimerobot.com (monitor setiap 5 menit)

---

## ARSITEKTUR SISTEM

```
┌─────────────────────────────────────────────┐
│              Railway Container               │
│                                             │
│  ┌──────────────┐    ┌───────────────────┐  │
│  │  Paperclip   │───▶│  Gemini Adapter   │  │
│  │  (port 3000) │    │  (port 11434)     │  │
│  │  Node.js     │    │  gemini-adapter.js│  │
│  │  350MB max   │    │  OpenAI-compat    │  │
│  └──────────────┘    └────────┬──────────┘  │
│                               │             │
└───────────────────────────────┼─────────────┘
                                │ HTTPS
                         ┌──────▼──────┐
                         │ Google      │
                         │ Gemini API  │
                         │ (Gratis!)   │
                         └─────────────┘
          ┌─────────────┐
          │  PostgreSQL  │
          │  Railway DB  │
          └─────────────┘
```

**Kenapa Gemini sebagai adapter LOKAL?**
- Paperclip dirancang untuk OpenAI API
- Gemini adapter "menerjemahkan" format OpenAI → Gemini
- Berjalan di dalam container yang sama (localhost)
- Tidak butuh internet untuk koneksi adapter (hanya ke Google API)
- Gratis! Gemini Flash tidak kena biaya untuk penggunaan normal

---

## TIPS HEMAT MEMORY (Railway Free Tier 512MB)

1. **Node.js heap limit** → sudah diset 350MB di entrypoint.sh
2. **GC agresif** → `--gc-interval=100` memicu garbage collection lebih sering
3. **Produksi only** → `npm install --omit=dev` tidak install devDependencies
4. **Docker layer cache** → copy package.json terpisah agar tidak rebuild total
5. **Slim base image** → pakai `node:20-slim` bukan `node:20` (hemat ~300MB)

---

*Dibuat untuk: Irvan - Paperclip Railway Deployment Guide*
*Versi: 1.0 | Gemini Adapter Edition*
