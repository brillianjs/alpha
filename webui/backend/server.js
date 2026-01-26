const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Configuration paths (adjust for your server)
const CONFIG = {
  xrayConfig: process.env.XRAY_CONFIG_PATH || '/etc/xray/config.json',
  vmessDb: process.env.VMESS_DB_PATH || '/etc/vmess/.vmess.db',
  vlessDb: process.env.VLESS_DB_PATH || '/etc/vless/.vless.db',
  trojanDb: process.env.TROJAN_DB_PATH || '/etc/trojan/.trojan.db',
  shadowsocksDb: process.env.SHADOWSOCKS_DB_PATH || '/etc/shadowsocks/.shadowsocks.db',
  sshDb: process.env.SSH_DB_PATH || '/etc/ssh/.ssh.db',
  domainPath: process.env.DOMAIN_PATH || '/etc/xray/domain'
};

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'brilltunnel-secret-key';

// Admin credentials (in production, use database)
const ADMIN = {
  username: process.env.ADMIN_USERNAME || 'admin',
  password: process.env.ADMIN_PASSWORD || 'admin123'
};

// Auth Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Helper Functions
const readFile = (filePath) => {
  try {
    if (fs.existsSync(filePath)) {
      return fs.readFileSync(filePath, 'utf8');
    }
    return null;
  } catch (error) {
    console.error(`Error reading file ${filePath}:`, error);
    return null;
  }
};

const writeFile = (filePath, content) => {
  try {
    fs.writeFileSync(filePath, content, 'utf8');
    return true;
  } catch (error) {
    console.error(`Error writing file ${filePath}:`, error);
    return false;
  }
};

const execCommand = (command) => {
  return new Promise((resolve, reject) => {
    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(error);
        return;
      }
      resolve(stdout);
    });
  });
};

const parseUserDb = (content) => {
  if (!content) return [];
  const lines = content.split('\n');
  const users = [];

  for (const line of lines) {
    if (line.startsWith('### ')) {
      const parts = line.substring(4).split(' ');
      if (parts.length >= 3) {
        users.push({
          username: parts[0],
          expiry: parts[1],
          uuid: parts[2],
          quota: parts[3] || '0',
          ipLimit: parts[4] || '0'
        });
      }
    }
  }
  return users;
};

const getDomain = () => {
  const domain = readFile(CONFIG.domainPath);
  return domain ? domain.trim() : 'localhost';
};

// ==================== AUTH ROUTES ====================

// Login
app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body;

  if (username === ADMIN.username && password === ADMIN.password) {
    const token = jwt.sign({ username }, JWT_SECRET, { expiresIn: '24h' });
    res.json({
      success: true,
      token,
      user: { username }
    });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});

// Verify Token
app.get('/api/auth/verify', authenticateToken, (req, res) => {
  res.json({ valid: true, user: req.user });
});

// ==================== DASHBOARD ROUTES ====================

// Get Dashboard Stats
app.get('/api/dashboard/stats', authenticateToken, async (req, res) => {
  try {
    const vmessUsers = parseUserDb(readFile(CONFIG.vmessDb));
    const vlessUsers = parseUserDb(readFile(CONFIG.vlessDb));
    const trojanUsers = parseUserDb(readFile(CONFIG.trojanDb));
    const ssUsers = parseUserDb(readFile(CONFIG.shadowsocksDb));

    // Get service status
    const services = {};
    const serviceNames = ['xray', 'nginx', 'haproxy', 'ssh', 'dropbear'];

    for (const service of serviceNames) {
      try {
        await execCommand(`systemctl is-active ${service}`);
        services[service] = 'running';
      } catch {
        services[service] = 'stopped';
      }
    }

    res.json({
      users: {
        vmess: vmessUsers.length,
        vless: vlessUsers.length,
        trojan: trojanUsers.length,
        shadowsocks: ssUsers.length,
        total: vmessUsers.length + vlessUsers.length + trojanUsers.length + ssUsers.length
      },
      services,
      domain: getDomain()
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ==================== VMESS ROUTES ====================

// Get all VMESS users
app.get('/api/vmess/users', authenticateToken, (req, res) => {
  const users = parseUserDb(readFile(CONFIG.vmessDb));
  res.json({ users, domain: getDomain() });
});

// Create VMESS user
app.post('/api/vmess/users', authenticateToken, async (req, res) => {
  try {
    const { username, days, quota = 0, ipLimit = 0 } = req.body;

    if (!username || !days) {
      return res.status(400).json({ error: 'Username and days are required' });
    }

    const uuid = uuidv4();
    const expiry = new Date();
    expiry.setDate(expiry.getDate() + parseInt(days));
    const expiryStr = expiry.toISOString().split('T')[0];
    const domain = getDomain();

    // Add to database file
    const dbContent = readFile(CONFIG.vmessDb) || '';
    const newEntry = `### ${username} ${expiryStr} ${uuid} ${quota} ${ipLimit}\n`;
    writeFile(CONFIG.vmessDb, dbContent + newEntry);

    // Generate links
    const vmessConfig = {
      v: "2",
      ps: username,
      add: domain,
      port: "443",
      id: uuid,
      aid: "0",
      net: "ws",
      path: "/vmess",
      type: "none",
      host: domain,
      tls: "tls"
    };

    const vmessLink = `vmess://${Buffer.from(JSON.stringify(vmessConfig)).toString('base64')}`;

    // Restart xray
    await execCommand('systemctl restart xray');

    res.json({
      success: true,
      user: {
        username,
        uuid,
        expiry: expiryStr,
        quota,
        ipLimit,
        domain,
        links: {
          tls: vmessLink
        }
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete VMESS user
app.delete('/api/vmess/users/:username', authenticateToken, async (req, res) => {
  try {
    const { username } = req.params;

    let dbContent = readFile(CONFIG.vmessDb) || '';
    const lines = dbContent.split('\n');
    const newLines = lines.filter(line => !line.includes(`### ${username} `));
    writeFile(CONFIG.vmessDb, newLines.join('\n'));

    await execCommand('systemctl restart xray');

    res.json({ success: true, message: `User ${username} deleted` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ==================== VLESS ROUTES ====================

// Get all VLESS users
app.get('/api/vless/users', authenticateToken, (req, res) => {
  const users = parseUserDb(readFile(CONFIG.vlessDb));
  res.json({ users, domain: getDomain() });
});

// Create VLESS user
app.post('/api/vless/users', authenticateToken, async (req, res) => {
  try {
    const { username, days, quota = 0, ipLimit = 0 } = req.body;

    if (!username || !days) {
      return res.status(400).json({ error: 'Username and days are required' });
    }

    const uuid = uuidv4();
    const expiry = new Date();
    expiry.setDate(expiry.getDate() + parseInt(days));
    const expiryStr = expiry.toISOString().split('T')[0];
    const domain = getDomain();

    // Add to database file
    const dbContent = readFile(CONFIG.vlessDb) || '';
    const newEntry = `### ${username} ${expiryStr} ${uuid} ${quota} ${ipLimit}\n`;
    writeFile(CONFIG.vlessDb, dbContent + newEntry);

    // Generate links
    const vlessLink = `vless://${uuid}@${domain}:443?path=/vless&security=tls&encryption=none&type=ws#${username}`;

    await execCommand('systemctl restart xray');

    res.json({
      success: true,
      user: {
        username,
        uuid,
        expiry: expiryStr,
        quota,
        ipLimit,
        domain,
        links: {
          tls: vlessLink
        }
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete VLESS user
app.delete('/api/vless/users/:username', authenticateToken, async (req, res) => {
  try {
    const { username } = req.params;

    let dbContent = readFile(CONFIG.vlessDb) || '';
    const lines = dbContent.split('\n');
    const newLines = lines.filter(line => !line.includes(`### ${username} `));
    writeFile(CONFIG.vlessDb, newLines.join('\n'));

    await execCommand('systemctl restart xray');

    res.json({ success: true, message: `User ${username} deleted` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ==================== TROJAN ROUTES ====================

// Get all Trojan users
app.get('/api/trojan/users', authenticateToken, (req, res) => {
  const users = parseUserDb(readFile(CONFIG.trojanDb));
  res.json({ users, domain: getDomain() });
});

// Create Trojan user
app.post('/api/trojan/users', authenticateToken, async (req, res) => {
  try {
    const { username, days, quota = 0, ipLimit = 0 } = req.body;

    if (!username || !days) {
      return res.status(400).json({ error: 'Username and days are required' });
    }

    const uuid = uuidv4();
    const expiry = new Date();
    expiry.setDate(expiry.getDate() + parseInt(days));
    const expiryStr = expiry.toISOString().split('T')[0];
    const domain = getDomain();

    // Add to database file
    const dbContent = readFile(CONFIG.trojanDb) || '';
    const newEntry = `### ${username} ${expiryStr} ${uuid} ${quota} ${ipLimit}\n`;
    writeFile(CONFIG.trojanDb, dbContent + newEntry);

    // Generate links
    const trojanLink = `trojan://${uuid}@${domain}:443?path=%2Ftrojan-ws&security=tls&host=${domain}&type=ws&sni=${domain}#${username}`;

    await execCommand('systemctl restart xray');

    res.json({
      success: true,
      user: {
        username,
        uuid,
        expiry: expiryStr,
        quota,
        ipLimit,
        domain,
        links: {
          ws: trojanLink
        }
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete Trojan user
app.delete('/api/trojan/users/:username', authenticateToken, async (req, res) => {
  try {
    const { username } = req.params;

    let dbContent = readFile(CONFIG.trojanDb) || '';
    const lines = dbContent.split('\n');
    const newLines = lines.filter(line => !line.includes(`### ${username} `));
    writeFile(CONFIG.trojanDb, newLines.join('\n'));

    await execCommand('systemctl restart xray');

    res.json({ success: true, message: `User ${username} deleted` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ==================== SHADOWSOCKS ROUTES ====================

// Get all Shadowsocks users
app.get('/api/shadowsocks/users', authenticateToken, (req, res) => {
  const users = parseUserDb(readFile(CONFIG.shadowsocksDb));
  res.json({ users, domain: getDomain() });
});

// Create Shadowsocks user
app.post('/api/shadowsocks/users', authenticateToken, async (req, res) => {
  try {
    const { username, days, quota = 0 } = req.body;

    if (!username || !days) {
      return res.status(400).json({ error: 'Username and days are required' });
    }

    const uuid = uuidv4();
    const expiry = new Date();
    expiry.setDate(expiry.getDate() + parseInt(days));
    const expiryStr = expiry.toISOString().split('T')[0];
    const domain = getDomain();
    const cipher = 'aes-128-gcm';

    // Add to database file
    const dbContent = readFile(CONFIG.shadowsocksDb) || '';
    const newEntry = `### ${username} ${expiryStr} ${uuid}\n`;
    writeFile(CONFIG.shadowsocksDb, dbContent + newEntry);

    // Generate links
    const ssBase64 = Buffer.from(`${cipher}:${uuid}`).toString('base64');
    const ssLink = `ss://${ssBase64}@${domain}:443?path=/ss-ws&security=tls&encryption=none&type=ws#${username}`;

    await execCommand('systemctl restart xray');

    res.json({
      success: true,
      user: {
        username,
        password: uuid,
        cipher,
        expiry: expiryStr,
        quota,
        domain,
        links: {
          ws: ssLink
        }
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete Shadowsocks user
app.delete('/api/shadowsocks/users/:username', authenticateToken, async (req, res) => {
  try {
    const { username } = req.params;

    let dbContent = readFile(CONFIG.shadowsocksDb) || '';
    const lines = dbContent.split('\n');
    const newLines = lines.filter(line => !line.includes(`### ${username} `));
    writeFile(CONFIG.shadowsocksDb, newLines.join('\n'));

    await execCommand('systemctl restart xray');

    res.json({ success: true, message: `User ${username} deleted` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ==================== SYSTEM ROUTES ====================

// Get system info
app.get('/api/system/info', authenticateToken, async (req, res) => {
  try {
    const uptime = await execCommand('uptime -p');
    const hostname = await execCommand('hostname');

    res.json({
      hostname: hostname.trim(),
      uptime: uptime.trim(),
      domain: getDomain()
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Restart service
app.post('/api/system/restart/:service', authenticateToken, async (req, res) => {
  try {
    const { service } = req.params;
    const allowedServices = ['xray', 'nginx', 'haproxy', 'ssh', 'dropbear'];

    if (!allowedServices.includes(service)) {
      return res.status(400).json({ error: 'Service not allowed' });
    }

    await execCommand(`systemctl restart ${service}`);
    res.json({ success: true, message: `Service ${service} restarted` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Start server
app.listen(PORT, () => {
  console.log(`BrillTunnel API running on port ${PORT}`);
});
