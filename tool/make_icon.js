// Renders FinTrack's launcher icon (dark rounded tile, rising green bars,
// violet accent dot) to PNG at every density Android and the web need.
// No image dependencies: raw RGBA buffer -> zlib -> PNG, drawn at 4x and
// box-filtered down for smooth edges.
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const SS = 4; // supersampling factor per axis

const BG_TOP = [16, 19, 24];
const BG_BOTTOM = [5, 6, 8];
const GREEN = [0, 230, 118];
const GREEN_DIM = [0, 190, 100];
const VIOLET = [139, 92, 246];

function crc32(buf) {
  let table = crc32.table;
  if (!table) {
    table = crc32.table = new Int32Array(256);
    for (let n = 0; n < 256; n++) {
      let c = n;
      for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
      table[n] = c;
    }
  }
  let crc = -1;
  for (let i = 0; i < buf.length; i++) crc = table[(crc ^ buf[i]) & 0xff] ^ (crc >>> 8);
  return (crc ^ -1) >>> 0;
}

function chunk(type, data) {
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length, 0);
  const typeBuf = Buffer.from(type, 'ascii');
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])), 0);
  return Buffer.concat([length, typeBuf, data, crc]);
}

function encodePng(width, height, rgba) {
  const raw = Buffer.alloc((width * 4 + 1) * height);
  for (let y = 0; y < height; y++) {
    raw[y * (width * 4 + 1)] = 0; // filter: none
    rgba.copy(raw, y * (width * 4 + 1) + 1, y * width * 4, (y + 1) * width * 4);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // colour type: RGBA
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

function drawIcon(size) {
  const S = size * SS;
  const px = Buffer.alloc(S * S * 4);

  const put = (x, y, r, g, b, a) => {
    if (x < 0 || y < 0 || x >= S || y >= S) return;
    const i = (y * S + x) * 4;
    const alpha = a / 255;
    px[i] = Math.round(px[i] * (1 - alpha) + r * alpha);
    px[i + 1] = Math.round(px[i + 1] * (1 - alpha) + g * alpha);
    px[i + 2] = Math.round(px[i + 2] * (1 - alpha) + b * alpha);
    px[i + 3] = Math.min(255, px[i + 3] + a);
  };

  const roundRect = (x0, y0, x1, y1, radius, color, alpha = 255) => {
    for (let y = Math.floor(y0); y < y1; y++) {
      for (let x = Math.floor(x0); x < x1; x++) {
        const cx = Math.min(Math.max(x, x0 + radius), x1 - radius);
        const cy = Math.min(Math.max(y, y0 + radius), y1 - radius);
        const d = Math.hypot(x + 0.5 - cx, y + 0.5 - cy);
        if (d > radius) continue;
        const edge = Math.min(1, radius - d + 0.5);
        put(x, y, color[0], color[1], color[2], alpha * Math.min(1, edge));
      }
    }
  };

  // Tile with a vertical gradient, clipped to a generous rounded square.
  const radius = S * 0.235;
  for (let y = 0; y < S; y++) {
    const t = y / (S - 1);
    const mix = [
      Math.round(BG_TOP[0] + (BG_BOTTOM[0] - BG_TOP[0]) * t),
      Math.round(BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * t),
      Math.round(BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * t),
    ];
    for (let x = 0; x < S; x++) {
      const cx = Math.min(Math.max(x, radius), S - radius);
      const cy = Math.min(Math.max(y, radius), S - radius);
      const d = Math.hypot(x + 0.5 - cx, y + 0.5 - cy);
      if (d > radius) continue;
      const edge = Math.min(1, radius - d + 0.5);
      put(x, y, mix[0], mix[1], mix[2], 255 * Math.min(1, edge));
    }
  }

  // Soft green bloom behind the bars.
  const bloom = { x: S * 0.5, y: S * 0.68, r: S * 0.42 };
  for (let y = Math.floor(bloom.y - bloom.r); y < bloom.y + bloom.r; y++) {
    for (let x = Math.floor(bloom.x - bloom.r); x < bloom.x + bloom.r; x++) {
      const d = Math.hypot(x - bloom.x, y - bloom.y) / bloom.r;
      if (d >= 1) continue;
      put(x, y, GREEN[0], GREEN[1], GREEN[2], 34 * (1 - d) ** 2);
    }
  }

  // A vertical capsule: body rectangle plus two round caps.
  const capsule = (cx, top, bottom, width, color, alpha) => {
    const r = width / 2;
    const paintCircle = (ccy, rad) => {
      for (let y = Math.floor(ccy - rad - 1); y <= ccy + rad + 1; y++) {
        for (let x = Math.floor(cx - rad - 1); x <= cx + rad + 1; x++) {
          const d = Math.hypot(x + 0.5 - cx, y + 0.5 - ccy);
          if (d > rad) continue;
          put(x, y, color[0], color[1], color[2], alpha * Math.min(1, rad - d + 0.5));
        }
      }
    };
    for (let y = Math.floor(top + r); y <= bottom - r; y++) {
      for (let x = Math.floor(cx - r); x <= cx + r; x++) {
        put(x, y, color[0], color[1], color[2], alpha);
      }
    }
    paintCircle(top + r, r);
    paintCircle(bottom - r, r);
  };

  // Three rising bars.
  const barW = S * 0.115;
  const baseY = 0.735; // fraction of the canvas; scaled below
  const bars = [0.4, 0.53, 0.66];
  const heights = [0.15, 0.24, 0.33];
  bars.forEach((bx, i) => {
    const color = i === bars.length - 1 ? GREEN : GREEN_DIM;
    capsule(S * bx, S * (baseY - heights[i]), S * baseY, barW, color, i === bars.length - 1 ? 255 : 215);
  });

  // Baseline.
  for (let y = Math.floor(S * 0.762); y < S * 0.762 + S * 0.012; y++) {
    for (let x = Math.floor(S * 0.3); x < S * 0.7; x++) {
      put(x, y, GREEN[0], GREEN[1], GREEN[2], 90);
    }
  }

  // Violet accent dot: the "spark" above the tallest bar.
  const dot = { x: S * 0.665, y: S * 0.345, r: S * 0.052 };
  for (let y = Math.floor(dot.y - dot.r); y < dot.y + dot.r; y++) {
    for (let x = Math.floor(dot.x - dot.r); x < dot.x + dot.r; x++) {
      const d = Math.hypot(x - dot.x, y - dot.y);
      if (d > dot.r) continue;
      put(x, y, VIOLET[0], VIOLET[1], VIOLET[2], 255 * Math.min(1, dot.r - d + 0.5));
    }
  }

  // Box-filter downsample.
  const out = Buffer.alloc(size * size * 4);
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      let r = 0, g = 0, b = 0, a = 0;
      for (let sy = 0; sy < SS; sy++) {
        for (let sx = 0; sx < SS; sx++) {
          const i = ((y * SS + sy) * S + (x * SS + sx)) * 4;
          r += px[i];
          g += px[i + 1];
          b += px[i + 2];
          a += px[i + 3];
        }
      }
      const n = SS * SS;
      const i = (y * size + x) * 4;
      out[i] = Math.round(r / n);
      out[i + 1] = Math.round(g / n);
      out[i + 2] = Math.round(b / n);
      out[i + 3] = Math.round(a / n);
    }
  }
  return encodePng(size, size, out);
}

const targets = [
  ['android/app/src/main/res/mipmap-mdpi/ic_launcher.png', 48],
  ['android/app/src/main/res/mipmap-hdpi/ic_launcher.png', 72],
  ['android/app/src/main/res/mipmap-xhdpi/ic_launcher.png', 96],
  ['android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png', 144],
  ['android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 192],
  ['web/favicon.png', 32],
  ['web/icons/Icon-192.png', 192],
  ['web/icons/Icon-512.png', 512],
  ['web/icons/Icon-maskable-192.png', 192],
  ['web/icons/Icon-maskable-512.png', 512],
];

for (const [file, size] of targets) {
  const abs = path.resolve(__dirname, '..', file);
  fs.mkdirSync(path.dirname(abs), { recursive: true });
  fs.writeFileSync(abs, drawIcon(size));
  console.log(`${file} (${size}px)`);
}
