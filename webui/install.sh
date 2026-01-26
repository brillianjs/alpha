#!/bin/bash

# BrillTunnel Web UI Installer
# This script installs and configures the Web UI for BrillTunnel VPN

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════╗"
echo "║     BrillTunnel Web UI Installer             ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${NC}"
  exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
FRONTEND_DIR="$SCRIPT_DIR/frontend"

# Check Node.js
echo -e "${YELLOW}[1/6] Checking Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Installing Node.js...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
fi
echo -e "${GREEN}Node.js version: $(node -v)${NC}"

# Install backend dependencies
echo -e "${YELLOW}[2/6] Installing backend dependencies...${NC}"
cd "$BACKEND_DIR"
npm install --production

# Configure environment
echo -e "${YELLOW}[3/6] Configuring environment...${NC}"
if [ ! -f "$BACKEND_DIR/.env" ]; then
    # Generate random JWT secret
    JWT_SECRET=$(openssl rand -hex 32)

    # Prompt for admin credentials
    read -p "Enter admin username [admin]: " ADMIN_USER
    ADMIN_USER=${ADMIN_USER:-admin}

    read -s -p "Enter admin password [admin123]: " ADMIN_PASS
    echo
    ADMIN_PASS=${ADMIN_PASS:-admin123}

    cat > "$BACKEND_DIR/.env" << EOF
PORT=3001
NODE_ENV=production
JWT_SECRET=$JWT_SECRET
ADMIN_USERNAME=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASS
XRAY_CONFIG_PATH=/etc/xray/config.json
VMESS_DB_PATH=/etc/vmess/.vmess.db
VLESS_DB_PATH=/etc/vless/.vless.db
TROJAN_DB_PATH=/etc/trojan/.trojan.db
SHADOWSOCKS_DB_PATH=/etc/shadowsocks/.shadowsocks.db
SSH_DB_PATH=/etc/ssh/.ssh.db
DOMAIN_PATH=/etc/xray/domain
EOF
    echo -e "${GREEN}Environment configured!${NC}"
else
    echo -e "${GREEN}Environment already configured.${NC}"
fi

# Install PM2
echo -e "${YELLOW}[4/6] Installing PM2...${NC}"
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2
fi
echo -e "${GREEN}PM2 installed!${NC}"

# Start API server with PM2
echo -e "${YELLOW}[5/6] Starting API server...${NC}"
cd "$BACKEND_DIR"
pm2 delete brilltunnel-api 2>/dev/null || true
pm2 start server.js --name brilltunnel-api
pm2 save
pm2 startup systemd -u root --hp /root

# Configure Nginx for Web UI
echo -e "${YELLOW}[6/6] Configuring Nginx...${NC}"

# Get domain
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "localhost")

# Create nginx config for panel
cat > /etc/nginx/conf.d/panel.conf << EOF
server {
    listen 8888;
    server_name $DOMAIN;

    root $FRONTEND_DIR;
    index index.html;

    # API Proxy
    location /api/ {
        proxy_pass http://127.0.0.1:3001/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_cache_bypass \$http_upgrade;
    }

    # Frontend
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

# Update frontend API URL
sed -i "s|apiUrl: 'http://localhost:3001/api'|apiUrl: '/api'|g" "$FRONTEND_DIR/index.html"

# Restart nginx
systemctl restart nginx

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete!                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Access your panel at:${NC}"
echo -e "  ${GREEN}http://$DOMAIN:8888${NC}"
echo -e "  ${GREEN}http://YOUR_IP:8888${NC}"
echo ""
echo -e "${BLUE}Default credentials:${NC}"
echo -e "  Username: ${GREEN}$ADMIN_USER${NC}"
echo -e "  Password: ${GREEN}(as configured)${NC}"
echo ""
echo -e "${YELLOW}Commands:${NC}"
echo -e "  pm2 status          - Check API status"
echo -e "  pm2 logs            - View API logs"
echo -e "  pm2 restart all     - Restart API"
echo ""
