FROM node:18-alpine
WORKDIR /usr/src/app
RUN apk add --no-cache wget
COPY backend/package.json backend/package-lock.json* ./
RUN npm install --production
COPY backend/ .
RUN addgroup -S appgroup && adduser -S appuser -G appgroup && chown -R appuser:appgroup /usr/src/app
USER appuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1
CMD ["node", "src/server.js"]
