# Bước 1: Chọn base image
FROM node:20-alpine

# Bước 2: Set working directory bên trong container
WORKDIR /app

# Bước 3: Copy package files từ thư mục gốc
COPY package*.json ./

# Bước 4: Cài production dependencies
RUN npm install --production

# Bước 5: Copy toàn bộ source code
COPY . .

# Bước 6: Tạo thư mục uploads theo đúng chuẩn README
RUN mkdir -p src/public/uploads

# Bước 7: Expose port app đang chạy
EXPOSE 3000

# Bước 8: Lệnh khởi động app
CMD ["node", "src/main.js"]