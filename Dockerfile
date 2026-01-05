# 빌드 스테이지
FROM node:18-alpine AS builder

# 작업 디렉토리 설정
WORKDIR /app

# package.json과 package-lock.json 복사
COPY package*.json ./

# 의존성 설치
RUN npm ci --only=production=false

# 소스 코드 복사
COPY . .

# prebuild 스크립트 실행 (notices index 생성)
RUN npm run prebuild

# 환경 변수 설정 (빌드 시 필요)
# 주의: 실제 배포 시에는 --build-arg로 전달하거나 .env 파일 사용
ARG REACT_APP_NAVER_CLIENT_ID
ARG REACT_APP_API_URL

ENV REACT_APP_NAVER_CLIENT_ID=$REACT_APP_NAVER_CLIENT_ID
ENV REACT_APP_API_URL=$REACT_APP_API_URL

# 프로덕션 빌드
RUN CI=false npm run build

# 프로덕션 스테이지
FROM nginx:alpine

# 빌드된 파일을 nginx 서빙 디렉토리로 복사
COPY --from=builder /app/build /usr/share/nginx/html

# nginx 설정 파일 생성 (nginx.conf가 없어도 작동)
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    gzip on; \
    gzip_vary on; \
    gzip_min_length 1024; \
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json; \
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
    } \
    location / { \
        try_files $uri $uri/ /index.html; \
        add_header Cache-Control "no-cache"; \
    } \
    add_header X-Frame-Options "SAMEORIGIN" always; \
    add_header X-Content-Type-Options "nosniff" always; \
    add_header X-XSS-Protection "1; mode=block" always; \
}' > /etc/nginx/conf.d/default.conf

# 포트 노출
EXPOSE 80

# Nginx 실행
CMD ["nginx", "-g", "daemon off;"]

