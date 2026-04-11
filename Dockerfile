FROM node:20-alpine

WORKDIR /app

# Copy package files từ thư mục src/
COPY src/package*.json ./

# Cài dependencies
RUN npm install --production

# Copy source code từ src/
COPY src/ ./src/

# Tạo thư mục uploads
RUN mkdir -p src/public/uploads

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "src/main.js"]