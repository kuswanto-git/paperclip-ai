# Menggunakan Node.js versi ringan untuk menghemat RAM di Railway Free Tier
FROM node:20-alpine

# Set environment produksi dan efisiensi memori
ENV NODE_ENV=production

# TRIK ANTI-OOM: Batasi penggunaan RAM Node.js maksimal 350MB dari limit 512MB Railway
ENV NODE_OPTIONS="--max-old-space-size=350"

WORKDIR /app

# Ambil source code Paperclip langsung dari rilis publik resmi
RUN apk add --no-cache git curl \
    && git clone https://github.com/agencyenterprise/paperclip-ai.git . \
    && npm ci --only=production

# Expose port untuk adapter lokal
EXPOSE 3000

# Jalankan aplikasi
CMD ["npm", "start"]
