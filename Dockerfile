FROM node:20.11-slim AS builder
WORKDIR /app
COPY app/package*.json ./
RUN npm ci

FROM node:20.11-slim
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY app/ ./
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => r.statusCode === 200 ? process.exit(0) : process.exit(1))"

CMD ["node", "src/index.js"]