# ---- Build Stage ----
FROM node:20-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --legacy-peer-deps

COPY tsconfig.json ./
COPY src/ ./src/

RUN npm run build

# ---- Production Stage ----
FROM node:20-alpine

RUN apk add --no-cache postgresql-client

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev --legacy-peer-deps

COPY --from=builder /app/dist ./dist
COPY migrations/ ./migrations/

COPY <<'EOF' /app/start.sh
#!/bin/sh
echo "Running migrations..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f migrations/001_create_users.sql
echo "Starting server..."
node dist/server.js
EOF
RUN chmod +x /app/start.sh

EXPOSE 4000

CMD ["/app/start.sh"]
