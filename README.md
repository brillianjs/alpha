# 🚀 BrillTunnel

<div align="center">

![BrillTunnel Logo](https://github.com/brillianjs/alpha/assets/158546743/ee0b4e39-3384-4cb9-bf74-ba72b89a2a43)

**Comprehensive VPN & Tunnel Management Solution**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](VERSION)
[![Support](https://img.shields.io/badge/support-Telegram-blue.svg)](https://t.me/brillianjs)

</div>

## 📋 Overview

**BrillTunnel** is a powerful, automated VPN and tunnel management system designed for Linux servers. It provides comprehensive support for multiple VPN protocols, automated bot integration, and advanced networking features with an intuitive management interface.

## ✨ Features

- 🔐 **Multi-Protocol Support**: SSH, WebSocket, V2Ray, Trojan, VLESS, VMESS
- 🤖 **Telegram Bot Integration**: Automated user management and notifications
- 🌐 **Cloudflare Integration**: Optimized CDN and SSL configuration
- 📊 **Real-time Monitoring**: Traffic, bandwidth, and connection tracking
- 🔧 **Auto Management**: User expiration, limits, and renewals
- 🛡️ **Security Features**: Built-in protection and access control
- 📱 **Mobile Friendly**: Responsive web panel and mobile app support

## 🚀 Quick Installation

### One-Line Installation

```bash
apt install -y && apt update -y && apt upgrade -y && wget -q https://raw.githubusercontent.com/brillianjs/alpha/main/premi.sh && chmod +x premi.sh && ./premi.sh
```

### Update Script

```bash
wget -q https://raw.githubusercontent.com/brillianjs/alpha/main/update.sh && chmod +x update.sh && ./update.sh
```

## 💻 System Requirements

### Supported Operating Systems

- **Ubuntu 20.04.05** ✅
- **Debian 10** ✅
- **Minimum RAM**: 512MB
- **Minimum Storage**: 2GB
- **Network**: IPv4 & IPv6 support

## ⚙️ Cloudflare Configuration

For optimal performance, configure your Cloudflare settings as follows:

```yaml
SSL/TLS Settings:
  - SSL/TLS: FULL
  - SSL/TLS Recommender: OFF
  - GRPC: ON
  - WebSocket: ON
  - Always Use HTTPS: OFF
  - Under Attack Mode: OFF

Security Settings:
  - Security Level: Medium
  - Challenge Passage: 30 minutes
```

## 🔌 Port Configuration

| Service     | Protocol | Port(s)    | Description         |
| ----------- | -------- | ---------- | ------------------- |
| WebSocket   | WS       | 80         | Standard WebSocket  |
| TLS/SSL     | WSS      | 443        | Secure WebSocket    |
| Enhanced WS | WS       | 80, 8080   | Enhanced WebSocket  |
| NoobzVPN    | TCP/UDP  | 2082, 8880 | Custom VPN Protocol |
| SSH         | TCP      | 22, 2222   | Secure Shell        |
| Dropbear    | TCP      | 109, 143   | Alternative SSH     |

## 🤖 Telegram Bot Setup

### Step 1: Create Telegram Bot

1. **Find BotFather**:

   - Open Telegram and search for `@BotFather`
   - Start conversation with `/start`

2. **Create New Bot**:
   ```
   /newbot
   ```
   - Choose bot name (e.g., "BrillTunnel Bot")
   - Choose username (e.g., "brilltunnel_bot")
   - Save the API token provided

### Step 2: Get Chat ID

1. **Find User ID Bot**:

   - Search for `@userinfobot` or `@get_id_bot`
   - Send `/start` command
   - Bot will return your Chat ID

2. **Alternative Method**:
   ```bash
   curl https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
   ```

## 📚 Usage Guide

### Basic Commands

```bash
# Access main menu
menu

# Check service status
systemctl status xray

# View active connections
ss -tulpn

# Monitor bandwidth
vnstat -d

# Restart services
systemctl restart nginx xray
```

### User Management

```bash
# Add new user
addws <username> <days>

# Check user limit
cekws <username>

# Delete expired users
delexp

# Renew user subscription
renewws <username> <days>
```

## 🛠️ Advanced Configuration

### Custom Domain Setup

1. Point your domain to server IP
2. Update Cloudflare DNS settings
3. Run domain configuration:
   ```bash
   addhost
   ```

### SSL Certificate Management

```bash
# Fix SSL certificates
fixcert

# Renew certificates
certbot renew --force-renewal
```

## 🔧 Troubleshooting

### Common Issues

| Issue                 | Solution                      |
| --------------------- | ----------------------------- |
| Service Offline       | `systemctl restart <service>` |
| SSL Certificate Error | Run `fixcert` command         |
| Bot Not Responding    | Check token and chat ID       |
| Connection Failed     | Verify port configuration     |

### ⚠️ Important Warnings

```
⚠️  If services show "OFF" status:
   1. Restart the specific service
   2. If still offline, reboot the VPS
   3. Check firewall settings
   4. Verify Cloudflare configuration
```

## 📊 Monitoring & Analytics

- **Real-time Dashboard**: Access via web panel
- **Traffic Analytics**: Detailed bandwidth reports
- **User Statistics**: Connection logs and usage
- **System Health**: CPU, RAM, and disk monitoring

## 🔐 Security Features

- **DDoS Protection**: Built-in mitigation
- **Access Control**: IP whitelisting/blacklisting
- **Encryption**: AES-256 encryption
- **Authentication**: Multi-factor authentication support

## 📞 Support & Community

- **Telegram**: [@brillianjs](https://t.me/brillianjs)
- **Issues**: [GitHub Issues](https://github.com/brillianjs/alpha/issues)
- **Documentation**: [Wiki](https://github.com/brillianjs/alpha/wiki)

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

---

<div align="center">

**Made with ❤️ by [Brillian](https://github.com/brillianjs)**

_BrillTunnel - Your Gateway to Secure Networking_

</div>
