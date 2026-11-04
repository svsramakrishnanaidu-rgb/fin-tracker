// Drives the running web build in headless Chrome over CDP to capture the real
// screenshots used in README.md. Usage: node tool/shot.js (server on :5599).
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const APP_URL = 'http://127.0.0.1:5600/';
const PORT = 9333;
const OUT = path.resolve(__dirname, '..', 'docs', 'screenshots');
const CHROME = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

const wait = (ms) => new Promise((r) => setTimeout(r, ms));

const pad = (n) => String(n).padStart(2, '0');
const now = new Date();

function expense(id, amountMinor, category, day, note, hour = 12) {
  const d = new Date(now.getFullYear(), now.getMonth(), day, hour, 20, 0);
  return {
    id,
    amountMinor,
    category,
    date: d.toISOString().slice(0, 19),
    note,
    createdAt: d.toISOString().slice(0, 19),
  };
}

const seed = [
  expense('ft-demo-01', 129900, 'shopping', now.getDate() - 2, 'Noise-cancelling headphones', 19),
  expense('ft-demo-02', 48000, 'food', now.getDate() - 2, 'Dinner with the design team', 21),
  expense('ft-demo-03', 2500, 'travel', now.getDate() - 3, 'Metro card top-up', 9),
  expense('ft-demo-04', 34900, 'groceries', now.getDate() - 4, 'Weekly vegetables and fruit', 18),
  expense('ft-demo-05', 189900, 'bills', now.getDate() - 5, 'Electricity bill — October', 8),
  expense('ft-demo-06', 79900, 'education', now.getDate() - 6, 'Flutter advanced course', 20),
  expense('ft-demo-07', 21500, 'health', now.getDate() - 7, 'Pharmacy — monthly refill', 11),
  expense('ft-demo-08', 29900, 'entertainment', now.getDate() - 8, 'Concert ticket', 17),
  expense('ft-demo-09', 15500, 'food', now.getDate() - 9, 'Coffee and snacks', 10),
];

const storagePayload = JSON.stringify(
  seed.map((e) => ({
    id: e.id,
    amountMinor: e.amountMinor,
    category: e.category,
    date: e.date,
    note: e.note,
    createdAt: e.createdAt,
  })),
);

async function main() {
  fs.mkdirSync(OUT, { recursive: true });
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'fintrack-shots-'));

  const chrome = spawn(
    CHROME,
    [
      '--headless=new',
      `--remote-debugging-port=${PORT}`,
      `--user-data-dir=${profile}`,
      '--no-first-run',
      '--no-default-browser-check',
      '--hide-scrollbars',
      '--enable-unsafe-swiftshader',
      '--use-angle=swiftshader',
      '--quiet',
      'about:blank',
    ],
    { stdio: 'ignore' },
  );

  let target = null;
  for (let i = 0; i < 40 && !target; i++) {
    await wait(250);
    try {
      const res = await fetch(`http://127.0.0.1:${PORT}/json/list`);
      const list = await res.json();
      target = list.find((t) => t.type === 'page');
    } catch (_) {
      /* not up yet */
    }
  }
  if (!target) throw new Error('Chrome did not expose a page target');

  const ws = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => {
    ws.addEventListener('open', resolve, { once: true });
    ws.addEventListener('error', reject, { once: true });
  });

  let nextId = 1;
  const pending = new Map();
  ws.addEventListener('message', (event) => {
    const msg = JSON.parse(event.data);
    if (msg.id && pending.has(msg.id)) {
      const { resolve, reject } = pending.get(msg.id);
      pending.delete(msg.id);
      msg.error ? reject(new Error(JSON.stringify(msg.error))) : resolve(msg.result);
    }
  });

  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      const id = nextId++;
      pending.set(id, { resolve, reject });
      ws.send(JSON.stringify({ id, method, params }));
    });

  const evaluate = async (expression) => {
    const res = await send('Runtime.evaluate', {
      expression,
      awaitPromise: true,
      returnByValue: true,
    });
    return res.result ? res.result.value : undefined;
  };

  const shot = async (name) => {
    const { data } = await send('Page.captureScreenshot', { format: 'png' });
    const file = path.join(OUT, name);
    fs.writeFileSync(file, Buffer.from(data, 'base64'));
    console.log('saved', path.relative(process.cwd(), file));
  };

  const waitForApp = async () => {
    for (let i = 0; i < 120; i++) {
      const ready = await evaluate(
        "!!document.querySelector('flutter-view') && !!document.querySelector('flt-glass-pane, flt-semantics-placeholder')",
      );
      if (ready) return;
      await wait(500);
    }
    throw new Error('Flutter app never rendered');
  };

  const enableSemantics = async () => {
    await evaluate(
      "(() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) { p.click(); return true; } return false; })()",
    );
    await wait(600);
  };

  const clickLabel = async (needle) => {
    const ok = await evaluate(`(() => {
      const needle = ${JSON.stringify(needle.toLowerCase())};
      const textOf = (n) => ((n.getAttribute('aria-label') || '') + ' ' + (n.textContent || '')).toLowerCase();
      const nodes = Array.from(document.querySelectorAll('flt-semantics'));
      const matches = nodes.filter((n) => textOf(n).includes(needle));
      // Prefer the deepest match so we hit the button, not its container.
      const hit =
        matches.find((n) =>
          !Array.from(n.querySelectorAll('flt-semantics')).some((c) => textOf(c).includes(needle)),
        ) || matches[0];
      if (!hit) return false;
      const r = hit.getBoundingClientRect();
      const x = r.left + r.width / 2;
      const y = r.top + r.height / 2;
      hit.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, clientX: x, clientY: y, pointerId: 1, isPrimary: true, pointerType: 'mouse' }));
      hit.dispatchEvent(new PointerEvent('pointerup', { bubbles: true, clientX: x, clientY: y, pointerId: 1, isPrimary: true, pointerType: 'mouse' }));
      hit.click();
      return true;
    })()`);
    if (!ok) console.warn('  ! no semantics node matched:', needle);
    await wait(1200);
    return ok;
  };

  await send('Page.enable');
  await send('Runtime.enable');
  await send('Emulation.setDeviceMetricsOverride', {
    width: 430,
    height: 932,
    deviceScaleFactor: 2,
    mobile: true,
  });

  // First load: seed local storage exactly as the app stores it, then reload.
  await send('Page.navigate', { url: APP_URL });
  await waitForApp();
  // shared_preferences_web JSON-encodes every stored value, so the payload
  // string has to be encoded once more to match what the plugin writes.
  await evaluate(
    `localStorage.setItem('flutter.fintrack.expenses.v1', ${JSON.stringify(
      JSON.stringify(storagePayload),
    )});
     localStorage.setItem('flutter.fintrack.theme.v1', ${JSON.stringify(
       JSON.stringify('signatureAmoled'),
     )}); true;`,
  );
  await send('Page.reload', { ignoreCache: false });
  await waitForApp();
  await wait(2200);
  await enableSemantics();
  await wait(900);
  await shot('01-dashboard-dark.png');

  await clickLabel('add expense');
  await wait(900);
  await shot('02-add-expense.png');

  await clickLabel('close');
  await wait(900);

  await clickLabel('dinner with the design team');
  await wait(1000);
  await shot('03-expense-detail.png');

  await clickLabel('back');
  await wait(900);

  await clickLabel('summary');
  await wait(1200);
  await shot('04-summary.png');

  await clickLabel('settings');
  await wait(1000);
  await shot('05-settings.png');

  await clickLabel('premium light');
  await wait(1400);
  await evaluate("document.querySelectorAll('flt-semantics[aria-label]').length");
  await shot('06-settings-light.png');

  await clickLabel('home');
  await wait(1200);
  await shot('07-dashboard-light.png');

  // Back to the default theme, then a damaged payload -> error state.
  await evaluate(
    `localStorage.setItem('flutter.fintrack.theme.v1', ${JSON.stringify(
      JSON.stringify('signatureAmoled'),
    )});
     localStorage.setItem('flutter.fintrack.expenses.v1', ${JSON.stringify(
       JSON.stringify('{damaged-json'),
     )}); true;`,
  );
  await send('Page.reload');
  await waitForApp();
  await wait(2200);
  await shot('08-error-state.png');

  // Empty storage -> the real empty state.
  await evaluate("localStorage.removeItem('flutter.fintrack.expenses.v1'); true;");
  await send('Page.reload');
  await waitForApp();
  await wait(2200);
  await shot('09-empty-state.png');

  ws.close();
  chrome.kill();
  console.log('done');
}

main().catch(async (error) => {
  console.error('screenshot run failed:', error.message);
  process.exitCode = 1;
});
