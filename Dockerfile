# Menggunakan Node.js versi Alpine yang sangat ringan dan hemat RAM
FROM node:20-alpine

# Set lingkungan produksi dan batasi RAM maksimal 350MB agar aman dari OOM
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=350"

WORKDIR /app

# 1. Install git & curl
# 2. Clone repositori Paperclip resmi
# 3. Gunakan 'npm install' biasa dengan flag hemat memori (bukan 'npm ci')
RUN apk add --no-cache git curl \
    && git clone https://github.com/agencyenterprise/paperclip-ai.git . \
    && npm install --omit=dev --no-audit --no-fund

# Buka port adapter
EXPOSE 3000

# Jalankan aplikasi
CMD ["npm", "start"]
