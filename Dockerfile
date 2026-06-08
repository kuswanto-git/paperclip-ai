# Menggunakan Node.js versi Alpine yang sangat ringan dan hemat RAM
FROM node:20-alpine

# Set lingkungan produksi dan batasi RAM maksimal 350MB agar aman dari OOM
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=350"

WORKDIR /app

# 1. Install git & curl
# 2. Clone repositori Paperclip resmi
# 3. Install dependensi dengan flag hemat memori
RUN apk add --no-cache git curl \
    && git clone https://github.com/agencyenterprise/paperclip-ai.git . \
    && npm install --omit=dev --no-audit --no-fund

# Buka port adapter
EXPOSE 3000

# SOLUSI JITU: Jalankan aplikasi langsung lewat Node, bukan lewat perintah npm start
CMD ["node", "src/index.js"]
