# Stage 1: Build dependencies - chỉ dùng để tải thư viện
FROM node:20-alpine AS builder
WORKDIR /app
COPY src/package*.json ./src/
RUN cd src && npm install

# Stage 2: Final production image - bản chạy thật, mượn thư viện từ stage 1 nên cực kỳ nhẹ
FROM node:20-alpine
WORKDIR /app

# Copy node_modules from builder
COPY --from=builder /app/src/node_modules ./src/node_modules
COPY src/ ./src/

# Ensure uploads directory exists
RUN mkdir -p src/public/uploads

EXPOSE 3000

# Healthcheck for Docker Swarm self-healing - wget để tự ktra xem web có đang phản hồi không
#nếu k phản hồi thì tự khởi động lại container đó bằng Docker Swarm
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "src/main.js"]