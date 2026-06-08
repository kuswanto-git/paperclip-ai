#!/bin/sh
# ============================================================
# entrypoint.sh - Railway Paperclip Startup Script
# Menjalankan Gemini adapter lokal + Paperclip server
# ============================================================

set -e

echo "================================================"
echo "  Paperclip Railway - Gemini Adapter Edition"
echo "================================================"

# ── 1. Validasi environment variables wajib ──────────────────
echo "[1/5] Memeriksa environment variables..."

if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL belum di-set!"
  echo "   → Tambahkan PostgreSQL plugin di Railway dashboard"
  exit 1
fi

if [ -z "$GEMINI_API_KEY" ] && [ -z "$OPENAI_API_KEY" ]; then
  echo "ERROR: Butuh minimal salah satu: GEMINI_API_KEY atau OPENAI_API_KEY"
  exit 1
fi

echo "✓ Environment variables OK"

# ── 2. Pastikan direktori ada & bisa ditulis ─────────────────
echo "[2/5] Menyiapkan direktori..."
mkdir -p /app/run-logs /app/data /app/tmp
chmod -R 777 /app/run-logs /app/data /app/tmp
echo "✓ Direktori siap"

# ── 3. Jalankan Gemini CLI sebagai background adapter ────────
echo "[3/5] Memulai Gemini CLI adapter..."

if [ -n "$GEMINI_API_KEY" ]; then
  # Set API key untuk gemini-cli
  export GEMINI_API_KEY="$GEMINI_API_KEY"
  
  # Jalankan gemini-cli sebagai local proxy di port 11434 (mirip Ollama)
  # Background process dengan log ke file
  node /app/gemini-adapter.js > /app/run-logs/gemini-adapter.log 2>&1 &
  ADAPTER_PID=$!
  
  echo "✓ Gemini adapter berjalan (PID: $ADAPTER_PID)"
  
  # Tunggu adapter siap (max 15 detik)
  for i in $(seq 1 15); do
    if curl -s http://localhost:11434/health > /dev/null 2>&1; then
      echo "✓ Adapter sudah merespons"
      break
    fi
    echo "  Menunggu adapter... ($i/15)"
    sleep 1
  done
  
  # Set OPENAI_BASE_URL agar Paperclip menggunakan adapter lokal
  export OPENAI_BASE_URL="http://localhost:11434/v1"
  export OPENAI_API_KEY="${GEMINI_API_KEY}"
  export AI_MODEL="${AI_MODEL:-gemini-2.0-flash}"
  
else
  echo "ℹ Menggunakan OpenAI API langsung (OPENAI_API_KEY tersedia)"
fi

# ── 4. Database migration (jika diperlukan) ──────────────────
echo "[4/5] Menjalankan database migration..."
if [ -f "/app/package.json" ] && grep -q '"db:push"' /app/package.json 2>/dev/null; then
  npx drizzle-kit push --force 2>/dev/null || echo "  ℹ Migration skipped atau sudah up-to-date"
elif [ -f "/app/package.json" ] && grep -q '"migrate"' /app/package.json 2>/dev/null; then
  npm run migrate 2>/dev/null || echo "  ℹ Migration skipped"
fi
echo "✓ Database siap"

# ── 5. Jalankan Paperclip dengan batasan memory ──────────────
echo "[5/5] Memulai Paperclip server..."
echo "   PORT: ${PORT:-3000}"
echo "   AI Model: ${AI_MODEL:-gemini-2.0-flash}"
echo "================================================"

# --max-old-space-size=350 → batasi Node.js heap ke 350MB
# Cocok untuk Railway free tier (512MB total RAM)
exec node --max-old-space-size=350 \
     --gc-interval=100 \
     $(npm bin)/tsx server/index.ts 2>&1 || \
exec node --max-old-space-size=350 \
     --gc-interval=100 \
     server/index.js
