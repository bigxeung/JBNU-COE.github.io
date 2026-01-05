# Docker 배포 가이드

## 사전 요구사항

- Docker 설치
- Docker Compose (또는 Docker Compose V2 플러그인)
- 환경 변수 설정 (REACT_APP_NAVER_CLIENT_ID, REACT_APP_API_URL)

### Docker 설치 확인

```bash
# Docker 설치 확인
docker --version

# Docker Compose 확인 (V2 플러그인 방식 - 권장)
docker compose version

# 또는 기존 docker-compose 확인
docker-compose --version
```

### Docker 설치 (Ubuntu)

Docker가 설치되어 있지 않은 경우:

```bash
# Docker 설치
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 현재 사용자를 docker 그룹에 추가 (sudo 없이 사용하기 위해)
sudo usermod -aG docker $USER

# 로그아웃 후 다시 로그인하거나 다음 명령어 실행
newgrp docker

# Docker Compose V2는 Docker와 함께 설치됩니다
docker compose version
```

## 배포 방법

### 1. 환경 변수 설정

`.env` 파일을 생성하거나 환경 변수를 직접 설정합니다:

```bash
REACT_APP_NAVER_CLIENT_ID=your_naver_client_id
REACT_APP_API_URL=your_api_url
```

또는 `.env` 파일을 생성:

```bash
echo "REACT_APP_NAVER_CLIENT_ID=your_naver_client_id" > .env
echo "REACT_APP_API_URL=your_api_url" >> .env
```

### 2. Docker 이미지 빌드 및 실행

#### 방법 1: Docker Compose 사용 (권장)

**최신 Docker (Docker Compose V2 플러그인) 사용:**

```bash
# 이미지 빌드 및 컨테이너 실행 (하이픈 없이)
docker compose up -d --build

# 로그 확인
docker compose logs -f

# 컨테이너 중지
docker compose down
```

**기존 docker-compose 사용 (별도 설치 필요):**

```bash
# docker-compose 설치 (Ubuntu)
sudo apt update
sudo apt install docker-compose

# 이미지 빌드 및 컨테이너 실행
docker-compose up -d --build

# 로그 확인
docker-compose logs -f

# 컨테이너 중지
docker-compose down
```

> **참고**: `docker-compose: command not found` 오류가 발생하면 `docker compose` (하이픈 없이)를 사용하거나 위의 설치 명령어로 docker-compose를 설치하세요.

#### 방법 2: Docker 명령어 직접 사용

```bash
# 이미지 빌드 (환경 변수 포함)
docker build \
  --build-arg REACT_APP_NAVER_CLIENT_ID=your_naver_client_id \
  --build-arg REACT_APP_API_URL=your_api_url \
  -t jbnu-coe-web:latest .

# 컨테이너 실행
docker run -d -p 80:80 --name jbnu-coe-web jbnu-coe-web:latest

# 로그 확인
docker logs -f jbnu-coe-web

# 컨테이너 중지 및 제거
docker stop jbnu-coe-web
docker rm jbnu-coe-web
```

### 3. 접속 확인

브라우저에서 `http://your-vm-ip` 또는 `http://localhost`로 접속하여 확인합니다.

## 포트 변경

기본 포트는 80번입니다. 다른 포트를 사용하려면:

- Docker Compose: `docker-compose.yml`의 `ports` 섹션 수정
- Docker: `docker run -p 8080:80 ...` 형식으로 변경

## 문제 해결

### docker-compose 명령어를 찾을 수 없음

**해결 방법 1: Docker Compose V2 사용 (권장)**
```bash
# 하이픈 없이 사용
docker compose up -d --build
```

**해결 방법 2: docker-compose 설치**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker-compose

# 설치 확인
docker-compose --version
```

### 빌드 실패
- Node.js 버전 확인 (18 이상 필요)
- 환경 변수가 올바르게 설정되었는지 확인
- Docker가 정상적으로 실행 중인지 확인: `sudo systemctl status docker`

### 컨테이너가 시작되지 않음
```bash
# 로그 확인
docker logs jbnu-coe-web

# 컨테이너 상태 확인
docker ps -a
```

### 정적 파일이 로드되지 않음
- Nginx 설정 확인
- 빌드된 파일이 올바르게 복사되었는지 확인

## 프로덕션 배포 권장 사항

1. **HTTPS 설정**: Nginx에 SSL 인증서 설정
2. **리버스 프록시**: 필요시 Nginx 앞에 리버스 프록시 배치
3. **모니터링**: 로그 및 헬스체크 설정
4. **백업**: 정기적인 이미지 백업

