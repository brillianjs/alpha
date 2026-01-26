# BrillTunnel Web UI

Web-based management panel for BrillTunnel VPN Server.

## Features

- 🔐 **Secure Authentication** - JWT-based login system
- 📊 **Dashboard** - Real-time statistics and service status
- 👥 **User Management** - Create, view, and delete VPN users
- 🔄 **Multi-Protocol Support** - VMess, VLess, Trojan, Shadowsocks
- 🛠️ **System Management** - Restart services from web interface
- 📋 **One-Click Copy** - Copy VPN configuration links instantly

## Quick Start

### 1. Install Backend Dependencies

```bash
cd webui/backend
npm install
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

Edit the `.env` file:
```env
PORT=3001
JWT_SECRET=your-secure-secret-key
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your-secure-password
```

### 3. Start the API Server

```bash
# Development
npm run dev

# Production
npm start
```

### 4. Access the Web UI

Open `webui/frontend/index.html` in your browser, or serve it with a web server:

```bash
# Using Python
cd webui/frontend
python3 -m http.server 8080

# Using Node.js http-server
npx http-server webui/frontend -p 8080
```

Then open: `http://localhost:8080`

## Production Deployment

### Using PM2 (Recommended)

```bash
# Install PM2
npm install -g pm2

# Start the API server
cd webui/backend
pm2 start server.js --name brilltunnel-api

# Save PM2 configuration
pm2 save
pm2 startup
```

### Using Systemd

Create `/etc/systemd/system/brilltunnel-api.service`:

```ini
[Unit]
Description=BrillTunnel API Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/path/to/webui/backend
ExecStart=/usr/bin/node server.js
Restart=on-failure
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

Then:
```bash
systemctl daemon-reload
systemctl enable brilltunnel-api
systemctl start brilltunnel-api
```

### Nginx Reverse Proxy

Add to your nginx configuration:

```nginx
# API Backend
location /api/ {
    proxy_pass http://127.0.0.1:3001/api/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
}

# Frontend
location /panel/ {
    alias /path/to/webui/frontend/;
    index index.html;
}
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - Login
- `GET /api/auth/verify` - Verify token

### Dashboard
- `GET /api/dashboard/stats` - Get statistics

### Users (VMess, VLess, Trojan, Shadowsocks)
- `GET /api/{protocol}/users` - List users
- `POST /api/{protocol}/users` - Create user
- `DELETE /api/{protocol}/users/:username` - Delete user

### System
- `GET /api/system/info` - System information
- `POST /api/system/restart/:service` - Restart service

## Default Credentials

- **Username:** admin
- **Password:** admin123

⚠️ **Change these immediately in production!**

## Security Notes

1. Always use HTTPS in production
2. Change default credentials
3. Use strong JWT secret
4. Restrict API access with firewall rules
5. Keep Node.js and dependencies updated

## Troubleshooting

### API Connection Failed
- Check if the backend is running: `pm2 status` or `systemctl status brilltunnel-api`
- Verify the API URL in `index.html` matches your server

### Permission Denied
- Ensure the API has read/write access to VPN config files
- Run with appropriate permissions (root may be required)

### Users Not Showing
- Check if the database files exist in `/etc/{protocol}/`
- Verify file permissions

## License

MIT License - See main repository for details.
