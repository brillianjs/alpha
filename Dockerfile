# BrillTunnel VPN - Docker Test Environment
# Change to ubuntu:20.04 or ubuntu:22.04 to test other versions
FROM ubuntu:24.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jakarta

# Install base packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    nano \
    vim \
    net-tools \
    iputils-ping \
    iproute2 \
    sudo \
    openssh-server \
    nginx \
    jq \
    cron \
    iptables \
    procps \
    lsb-release \
    ca-certificates \
    gnupg \
    socat \
    unzip \
    zip \
    ruby \
    python3 \
    openssl \
    netcat-openbsd \
    figlet \
    pwgen \
    chrony \
    && rm -rf /var/lib/apt/lists/*

# Install lolcat
RUN gem install lolcat --no-document 2>/dev/null || gem install lolcat

# Create necessary directories
RUN mkdir -p /etc/xray \
    && mkdir -p /var/lib/brilltunnel \
    && mkdir -p /root/.info \
    && mkdir -p /usr/local/sbin \
    && mkdir -p /var/www/html \
    && mkdir -p /etc/vmess \
    && mkdir -p /etc/vless \
    && mkdir -p /etc/trojan \
    && mkdir -p /etc/shadowsocks \
    && mkdir -p /etc/bot

# Set default domain for testing
RUN echo "test.brilltunnel.com" > /etc/xray/domain \
    && echo "Unknown ISP" > /root/.info/.isp \
    && echo "Jakarta" > /root/.info/.city

# Create fake user/version files for menu
RUN echo "admin" > /usr/bin/user \
    && echo "1.0.0" > /usr/bin/ver \
    && echo "2025-12-31" > /usr/bin/e

# Create empty database files
RUN touch /etc/vmess/.vmess.db \
    && touch /etc/vless/.vless.db \
    && touch /etc/trojan/.trojan.db \
    && touch /etc/shadowsocks/.shadowsocks.db

# Create fake xray config
RUN echo '{"inbounds":[],"outbounds":[]}' > /etc/xray/config.json

# Copy the script files
WORKDIR /root/brilltunnel
COPY . .

# Make scripts executable
RUN find . -type f -name "*.sh" -exec chmod +x {} \; \
    && find ./menu -type f -exec chmod +x {} \; \
    && find ./files -type f -exec chmod +x {} \;

# Copy menu scripts to /usr/local/sbin for global access
RUN cp -r menu/* /usr/local/sbin/ 2>/dev/null || true

# Install Web UI dependencies
WORKDIR /root/brilltunnel/webui/backend
RUN npm install --production

# Create .env file for Web UI
RUN echo "PORT=3001" > .env \
    && echo "NODE_ENV=production" >> .env \
    && echo "JWT_SECRET=$(openssl rand -hex 32)" >> .env \
    && echo "ADMIN_USERNAME=admin" >> .env \
    && echo "ADMIN_PASSWORD=admin123" >> .env \
    && echo "XRAY_CONFIG_PATH=/etc/xray/config.json" >> .env \
    && echo "VMESS_DB_PATH=/etc/vmess/.vmess.db" >> .env \
    && echo "VLESS_DB_PATH=/etc/vless/.vless.db" >> .env \
    && echo "TROJAN_DB_PATH=/etc/trojan/.trojan.db" >> .env \
    && echo "SHADOWSOCKS_DB_PATH=/etc/shadowsocks/.shadowsocks.db" >> .env \
    && echo "DOMAIN_PATH=/etc/xray/domain" >> .env

# Configure Nginx for Web UI
RUN echo 'server { \n\
    listen 8888; \n\
    server_name _; \n\
    root /root/brilltunnel/webui/frontend; \n\
    index index.html; \n\
    location /api/ { \n\
        proxy_pass http://127.0.0.1:3001/api/; \n\
        proxy_http_version 1.1; \n\
        proxy_set_header Host $host; \n\
        proxy_set_header X-Real-IP $remote_addr; \n\
    } \n\
    location / { \n\
        try_files $uri $uri/ /index.html; \n\
    } \n\
}' > /etc/nginx/conf.d/panel.conf

# Update frontend API URL
RUN sed -i "s|apiUrl: 'http://localhost:3001/api'|}apiUrl: '/api'|g" /root/brilltunnel/webui/frontend/index.html 2>/dev/null || true

# Create startup script
RUN echo '#!/bin/bash\n\
service nginx start\n\
cd /root/brilltunnel/webui/backend && pm2 start server.js --name brilltunnel-api\n\
echo ""\n\
echo "══════════════════════════════════════════════════════════"\n\
echo "  🚀 BrillTunnel VPN - Docker Test Environment"\n\
echo "══════════════════════════════════════════════════════════"\n\
echo ""\n\
echo "  Web UI: http://localhost:8888"\n\
echo "  Login:  admin / admin123"\n\
echo ""\n\
echo "  Commands:"\n\
echo "    menu     - Open VPN menu"\n\
echo "    pm2 logs - View Web UI logs"\n\
echo ""\n\
echo "══════════════════════════════════════════════════════════"\n\
exec /bin/bash' > /start.sh && chmod +x /start.sh

WORKDIR /root/brilltunnel

# Expose ports
EXPOSE 22 80 443 8080 8443 8888 3001

# Default command
CMD ["/start.sh"]
