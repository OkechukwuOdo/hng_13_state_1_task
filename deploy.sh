#!/bin/bash
# ===============================================================
#  deploy.sh
#  Automates setup, deployment, and configuration of a Dockerized
#  application on a remote Linux server.
# ===============================================================

set -euo pipefail
IFS=$'\n\t'

# ---------- CONFIGURATION ----------
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="deploy_${TIMESTAMP}.log"
SSH_OPTS="-o StrictHostKeyChecking=no -o BatchMode=yes"

# ---------- LOGGING ----------
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_FILE"
}

trap 'log "❌ Error on line $LINENO. Exiting."; exit 1' ERR

# ---------- STEP 1: Collect User Inputs ----------
read -rp "Enter Git repository URL: " GIT_REPO
read -rp "Enter your Personal Access Token (PAT): " PAT
read -rp "Enter branch name [default: main]: " BRANCH
BRANCH=${BRANCH:-main}

read -rp "Enter SSH username: " REMOTE_USER
read -rp "Enter remote server IP address: " REMOTE_HOST
read -rp "Enter SSH private key path [~/.ssh/id_rsa]: " SSH_KEY
SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}
read -rp "Enter application internal port (e.g., 8080): " APP_PORT

REMOTE_APP_DIR="/opt/$(basename "$GIT_REPO" .git)"

# ---------- STEP 2: Clone or Update Repository ----------
log "📦 Cloning or updating repository..."
if [ -d "$(basename "$GIT_REPO" .git)" ]; then
  cd "$(basename "$GIT_REPO" .git)"
  git pull origin "$BRANCH" | tee -a "../$LOG_FILE"
else
  REPO_WITH_TOKEN=$(echo "$GIT_REPO" | sed "s#https://#https://${PAT}@#")
  git clone -b "$BRANCH" "$REPO_WITH_TOKEN" | tee -a "$LOG_FILE"
  cd "$(basename "$GIT_REPO" .git)"
fi

if [ ! -f "Dockerfile" ] && [ ! -f "docker-compose.yml" ]; then
  log "❌ No Dockerfile or docker-compose.yml found. Aborting."
  exit 2
fi
log "✅ Repository ready."

# ---------- STEP 3: Check SSH Connectivity ----------
log "🔑 Checking SSH connectivity..."
if ! ssh -i "$SSH_KEY" $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "echo connected"; then
  log "❌ SSH connection failed. Aborting."
  exit 3
fi
log "✅ SSH connection established."

# ---------- STEP 4: Prepare Remote Environment ----------
log "⚙️ Preparing remote environment..."
ssh -i "$SSH_KEY" $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" bash <<EOF
set -e
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release nginx git

# Install Docker if missing
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker $USER
fi

# Install Docker Compose if missing
if ! command -v docker-compose >/dev/null 2>&1; then
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl enable nginx
sudo systemctl start nginx
EOF
log "✅ Remote environment ready."

# ---------- STEP 5: Transfer Files ----------
log "📤 Transferring project files to remote server..."
rsync -az -e "ssh -i $SSH_KEY" ./ "$REMOTE_USER@$REMOTE_HOST:$REMOTE_APP_DIR/"
log "✅ Files transferred."

# ---------- STEP 6: Deploy Dockerized Application ----------
log "🐳 Deploying Docker containers..."
ssh -i "$SSH_KEY" $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" bash <<EOF
set -e
cd "$REMOTE_APP_DIR"

if [ -f "docker-compose.yml" ]; then
  docker-compose down || true
  docker-compose up -d --build
else
  docker stop myapp || true && docker rm myapp || true
  docker build -t myapp .
  docker run -d -p $APP_PORT:$APP_PORT --name myapp myapp
fi
EOF
log "✅ Docker application deployed."

# ---------- STEP 7: Configure Nginx ----------
log "🌐 Configuring Nginx reverse proxy..."
ssh -i "$SSH_KEY" $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" bash <<EOF
set -e
NGINX_CONF="/etc/nginx/sites-available/myapp"
sudo bash -c "cat > \$NGINX_CONF" <<NGINXCONF
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
NGINXCONF
sudo ln -sf \$NGINX_CONF /etc/nginx/sites-enabled/myapp
sudo nginx -t
sudo systemctl reload nginx
EOF
log "✅ Nginx configured as reverse proxy."

# ---------- STEP 8: Validate Deployment ----------
log "🧪 Validating deployment..."
ssh -i "$SSH_KEY" $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" bash <<EOF
set -e
echo "Checking Docker status..."
sudo systemctl is-active docker || exit 4

echo "Checking running containers..."
docker ps

echo "Testing application locally..."
curl -f http://127.0.0.1:$APP_PORT || exit 5
EOF
log "✅ Validation complete. Application is running and reachable."

# ---------- STEP 9: Cleanup Option ----------
if [[ "${1:-}" == "--cleanup" ]]; then
  log "🧹 Cleanup mode activated. Removing deployment..."
  ssh -i "$SSH_KEY" $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "sudo rm -rf $REMOTE_APP_DIR"
  log "✅ Cleanup complete."
fi

log "🎉 Deployment finished successfully! Log file: $LOG_FILE"

