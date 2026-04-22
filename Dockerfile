# syntax=docker/dockerfile:1.7

# =============================================================================
# Builder stage — installs production dependencies only, on a fresh Node base.
# =============================================================================

FROM node:20.11-slim AS builder

WORKDIR /app

# Copy package files first (better layer caching), then install prod deps only
COPY app/package.json app/package-lock.json ./
RUN npm ci --omit=dev

# Copy the rest of the app source
COPY . .

# =============================================================================
# Runtime stage — slim final image. Nothing from builder's caches leaks in.
# =============================================================================

FROM node:20.11-slim

WORKDIR /app

# Copy the fully-installed app from the builder stage
COPY --from=builder /app .

ENV NODE_ENV=production
EXPOSE 3000

# Healthcheck using Node's built-in http module (curl/wget not available in slim)
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode===200?0:1)).on('error', () => process.exit(1))"

CMD ["node", "src/index.js"]