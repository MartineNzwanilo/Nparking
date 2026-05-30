const fs = require('fs');
const https = require('https');
const path = require('path');

const icons = [
  // Sidebar & BottomNav
  { name: 'dashboard.png', url: 'https://img.icons8.com/fluency/96/dashboard.png' },
  { name: 'dashboard.gif', url: 'https://img.icons8.com/color/96/dashboard.gif' },
  { name: 'security-camera.png', url: 'https://img.icons8.com/fluency/96/security-camera.png' },
  { name: 'security-camera.gif', url: 'https://img.icons8.com/color/96/security-camera.gif' },
  { name: 'car.png', url: 'https://img.icons8.com/fluency/96/car.png' },
  { name: 'car.gif', url: 'https://img.icons8.com/color/96/car.gif' },
  { name: 'combo-chart.png', url: 'https://img.icons8.com/fluency/96/combo-chart.png' },
  { name: 'combo-chart.gif', url: 'https://img.icons8.com/color/96/combo-chart.gif' },
  { name: 'settings.png', url: 'https://img.icons8.com/fluency/96/settings.png' },
  { name: 'settings.gif', url: 'https://img.icons8.com/color/96/settings.gif' },
  { name: 'user-male-circle.png', url: 'https://img.icons8.com/fluency/96/user-male-circle.png' },
  
  // Header
  { name: 'menu.png', url: 'https://img.icons8.com/fluency/96/menu.png' },
  { name: 'forward.png', url: 'https://img.icons8.com/fluency/96/forward.png' },
  { name: 'expand.png', url: 'https://img.icons8.com/fluency/96/expand.png' },
  { name: 'collapse.png', url: 'https://img.icons8.com/fluency/96/collapse.png' },
  { name: 'sun.png', url: 'https://img.icons8.com/fluency/96/sun.png' },
  { name: 'moon-symbol.png', url: 'https://img.icons8.com/fluency/96/moon-symbol.png' },
  { name: 'bell.png', url: 'https://img.icons8.com/fluency/96/bell.png' },
  { name: 'bell.gif', url: 'https://img.icons8.com/color/96/bell.gif' },
  { name: 'box.png', url: 'https://img.icons8.com/fluency/96/box.png' },
  { name: 'box.gif', url: 'https://img.icons8.com/color/96/box.gif' },
  { name: 'exit.png', url: 'https://img.icons8.com/fluency/96/exit.png' },
  
  // Settings Drawer
  { name: 'multiply.png', url: 'https://img.icons8.com/fluency/96/multiply.png' },
  { name: 'monitor.png', url: 'https://img.icons8.com/fluency/96/monitor.png' },
  { name: 'checkmark.png', url: 'https://img.icons8.com/fluency/96/checkmark.png' },
  { name: 'align-left.png', url: 'https://img.icons8.com/fluency/96/align-left.png' },
  { name: 'align-right.png', url: 'https://img.icons8.com/fluency/96/align-right.png' },
  { name: 'text.png', url: 'https://img.icons8.com/fluency/96/text.png' },
  { name: 'synchronize.png', url: 'https://img.icons8.com/fluency/96/synchronize.png' },
  { name: 'lock.png', url: 'https://img.icons8.com/fluency/96/lock.png' },
  { name: 'parking.png', url: 'https://img.icons8.com/fluency/96/parking.png' },
];

const targetDir = path.join(__dirname, 'public', 'icons');

if (!fs.existsSync(targetDir)) {
  fs.mkdirSync(targetDir, { recursive: true });
}

function download(url, filePath) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        download(res.headers.location, filePath).then(resolve).catch(reject);
        return;
      }
      if (res.statusCode !== 200) {
        reject(new Error(`Failed to download: ${res.statusCode}`));
        return;
      }
      const fileStream = fs.createWriteStream(filePath);
      res.pipe(fileStream);
      fileStream.on('finish', () => {
        fileStream.close();
        console.log(`Downloaded ${url} to ${filePath}`);
        resolve();
      });
    }).on('error', (err) => {
      reject(err);
    });
  });
}

async function main() {
  for (const icon of icons) {
    const filePath = path.join(targetDir, icon.name);
    try {
      await download(icon.url, filePath);
    } catch (err) {
      console.error(`Error downloading ${icon.name}:`, err.message);
    }
  }
}

main();
