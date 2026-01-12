# Docker 자동 배포 가이드

## 개요

GitHub Actions를 통해 main 브랜치에 푸시가 발생하면 자동으로 VM에 SSH 접속하여 Docker 컨테이너를 재빌드하고 재시작합니다.

## 자동 재시작 설정

### 1. Docker Compose 재시작 정책
- `restart: unless-stopped`: 컨테이너가 수동으로 중지되지 않는 한 자동으로 재시작됩니다.
- 시스템 재부팅 시에도 자동으로 시작됩니다.

### 2. Healthcheck
- 30초마다 헬스체크를 수행하여 컨테이너 상태를 모니터링합니다.
- 문제 발생 시 자동으로 재시작됩니다.

## GitHub Secrets 설정

GitHub 저장소의 Settings > Secrets and variables > Actions에서 다음 Secrets를 설정해야 합니다:

### 필수 Secrets

1. **VM_HOST**: VM의 IP 주소 또는 도메인
   ```
   예: 192.168.1.100 또는 your-vm.example.com
   ```

2. **VM_USER**: SSH 접속 사용자명
   ```
   예: ubuntu
   ```

3. **VM_SSH_KEY**: SSH 개인 키 (전체 내용)
   ```
   -----BEGIN OPENSSH PRIVATE KEY-----
   ...
   -----END OPENSSH PRIVATE KEY-----
   ```

4. **VM_PORT**: SSH 포트 (선택사항, 기본값: 22)
   ```
   예: 22
   ```

5. **REACT_APP_NAVER_CLIENT_ID**: 네이버 지도 API Client ID
   ```
   예: your_naver_client_id
   ```

6. **REACT_APP_API_URL**: API 서버 URL
   ```
   예: https://api.example.com
   ```

## SSH 키 생성 및 설정

### 1. SSH 키 생성 (로컬에서)

```bash
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions_deploy
```

### 2. 공개 키를 VM에 추가

```bash
# 공개 키를 VM에 복사
ssh-copy-id -i ~/.ssh/github_actions_deploy.pub ubuntu@your-vm-ip
```

또는 수동으로:

```bash
# VM에 접속
ssh ubuntu@your-vm-ip

# ~/.ssh/authorized_keys 파일에 공개 키 추가
echo "공개키 내용" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 3. 개인 키를 GitHub Secrets에 추가

```bash
# 개인 키 내용 확인
cat ~/.ssh/github_actions_deploy

# 전체 내용을 복사하여 GitHub Secrets의 VM_SSH_KEY에 추가
```

## VM 초기 설정

VM에서 다음 명령어를 실행하여 프로젝트를 클론하고 초기 설정을 완료합니다:

```bash
# 프로젝트 디렉토리로 이동
cd ~

# 저장소 클론 (이미 있다면 생략)
git clone https://github.com/JBNU-COE/JBNU-COE.github.io.git
cd JBNU-COE.github.io

# .env 파일 생성
cat > .env << EOF
REACT_APP_NAVER_CLIENT_ID=your_naver_client_id
REACT_APP_API_URL=your_api_url
EOF

# Docker 및 Docker Compose 설치 확인
docker --version
docker compose version

# 첫 배포 실행
docker compose up -d --build
```

## 배포 프로세스

### 자동 배포

1. main 브랜치에 코드 푸시
2. GitHub Actions가 자동으로 트리거됨
3. VM에 SSH 접속
4. 최신 코드로 업데이트
5. Docker 이미지 재빌드
6. 컨테이너 재시작

### 수동 배포

GitHub Actions 탭에서 "Docker Deploy to VM" workflow를 선택하고 "Run workflow" 버튼을 클릭합니다.

## 배포 확인

### GitHub Actions에서 확인

1. GitHub 저장소의 Actions 탭으로 이동
2. "Docker Deploy to VM" workflow 실행 상태 확인
3. 로그를 확인하여 배포 성공 여부 확인

### VM에서 확인

```bash
# 컨테이너 상태 확인
docker compose ps

# 로그 확인
docker compose logs -f

# 최근 로그 확인
docker compose logs --tail=100
```

## 문제 해결

### SSH 연결 실패

- VM_SSH_KEY가 올바르게 설정되었는지 확인
- VM의 방화벽에서 SSH 포트(22)가 열려있는지 확인
- VM_USER와 VM_HOST가 올바른지 확인

### 배포 실패

- VM에 Docker와 Docker Compose가 설치되어 있는지 확인
- 프로젝트 디렉토리 경로가 올바른지 확인 (`~/JBNU-COE.github.io`)
- GitHub Secrets의 환경 변수가 올바르게 설정되었는지 확인

### 컨테이너가 재시작되지 않음

- `docker compose ps`로 컨테이너 상태 확인
- `docker compose logs`로 에러 로그 확인
- `restart: unless-stopped` 설정이 올바른지 확인

## 시스템 재부팅 시 자동 시작

Docker Compose의 `restart: unless-stopped` 정책으로 시스템 재부팅 시에도 자동으로 컨테이너가 시작됩니다.

추가로 시스템 서비스로 등록하려면:

```bash
# systemd 서비스 파일 생성 (선택사항)
sudo nano /etc/systemd/system/docker-compose-jbnu-coe.service
```

```ini
[Unit]
Description=Docker Compose JBNU-COE
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/JBNU-COE.github.io
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
User=ubuntu
Group=ubuntu

[Install]
WantedBy=multi-user.target
```

```bash
# 서비스 활성화
sudo systemctl enable docker-compose-jbnu-coe.service
sudo systemctl start docker-compose-jbnu-coe.service
```

## 모니터링

### 컨테이너 상태 모니터링

```bash
# 실시간 상태 확인
watch -n 1 'docker compose ps'

# 리소스 사용량 확인
docker stats jbnu-coe-web
```

### 로그 모니터링

```bash
# 실시간 로그 확인
docker compose logs -f

# 특정 시간 이후 로그
docker compose logs --since 1h
```

