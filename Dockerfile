# ============================================================
# Paperclip Railway Dockerfile - Gemini Adapter Edition
# Optimized for Railway Free Tier (512MB RAM limit)
# ============================================================

FROM node:20-slim

# Install dependencies minimal (hemat memory & image size)
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Install Gemini CLI secara global (adapter lokal)
RUN npm install -g @google/gemini-cli --ignore-scripts \
    && npm cache clean --force

# Set working directory
WORKDIR /app

# Clone Paperclip dari repo resmi
RUN git clone https://github.com/Lukem121/paperclip.git . \
    && rm -rf .git

# Install dependencies produksi saja (bukan devDependencies)
RUN npm install --omit=dev \
    && npm cache clean --force

# Buat direktori yang dibutuhkan
RUN mkdir -p /app/run-logs /app/data /app/tmp

# Copy file konfigurasi dari project kita
COPY entrypoint.sh /entrypoint.sh
COPY gemini-adapter.js /app/gemini-adapter.js

# Beri izin eksekusi
RUN chmod +x /entrypoint.sh

# Expose port (Railway akan override via PORT env)
EXPOSE 3000

# Healthcheck agar Railway tahu app sudah siap
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${PORT:-3000}/health || exit 1

# Jalankan via entrypoint
ENTRYPOINT ["/entrypoint.sh"]
