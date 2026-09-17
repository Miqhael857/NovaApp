// Generates the NovaPay UI design artboards (design/artboards/*.dc.html) and canvas.json.
// Run: node design/build-artboards.mjs
import { writeFileSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const OUT = join(dirname(fileURLToPath(import.meta.url)), 'artboards');
mkdirSync(OUT, { recursive: true });

// Text scale: 1 = default, 2 = "200% text" artboards (Android-style non-linear: large text grows less).
let SCALE = 1;
const t = (size, lh) => {
  const f = SCALE === 1 ? 1 : size <= 16 ? 2 : 1.5;
  return `font-size:${Math.round(size * f)}px;line-height:${Math.round(lh * f)}px;`;
};
const NUM = 'font-variant-numeric:tabular-nums;';
const MONO = 'font-family:ui-monospace, SFMono-Regular, Menlo, monospace;';

const ICONS = {
  back: '<path d="M15 18l-6-6 6-6"></path>',
  send: '<path d="M7 17L17 7"></path><path d="M9 7h8v8"></path>',
  receive: '<path d="M17 7L7 17"></path><path d="M15 17H7V9"></path>',
  target: '<circle cx="12" cy="12" r="9"></circle><circle cx="12" cy="12" r="5"></circle><circle cx="12" cy="12" r="1.5"></circle>',
  home: '<path d="M3 10.5L12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z"></path>',
  user: '<circle cx="12" cy="8" r="4"></circle><path d="M4 21c0-4 4-6 8-6s8 2 8 6"></path>',
  eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"></path><circle cx="12" cy="12" r="3"></circle>',
  wifiOff: '<path d="M3 3l18 18"></path><path d="M8.5 16.5a5 5 0 0 1 7 0"></path><path d="M5 12.9a10 10 0 0 1 4.2-2.5"></path><path d="M14.8 10.4A10 10 0 0 1 19 12.9"></path><path d="M2 8.8a15 15 0 0 1 3.6-2.4"></path><path d="M10 5.1A15 15 0 0 1 22 8.8"></path><path d="M12 20h.01"></path>',
  clock: '<circle cx="12" cy="12" r="9"></circle><path d="M12 7v5l3 2"></path>',
  alert: '<circle cx="12" cy="12" r="9"></circle><path d="M12 7.5v5.5"></path><path d="M12 16.5h.01"></path>',
  check: '<path d="M5 12.5l4.5 4.5L19 7.5"></path>',
  chevronDown: '<path d="M6 9l6 6 6-6"></path>',
  chevronRight: '<path d="M9 6l6 6-6 6"></path>',
  bank: '<path d="M3 10l9-6 9 6"></path><path d="M5 10v8M9.5 10v8M14.5 10v8M19 10v8"></path><path d="M3 21h18"></path>',
  calendar: '<rect x="3" y="5" width="18" height="16" rx="2"></rect><path d="M3 10h18M8 3v4M16 3v4"></path>',
  phone: '<rect x="7" y="2.5" width="10" height="19" rx="2"></rect><path d="M11 18h2"></path>',
  plus: '<path d="M12 5v14M5 12h14"></path>',
  shield: '<path d="M12 3l8 3v6c0 4.5-3.4 8.3-8 9-4.6-.7-8-4.5-8-9V6z"></path><path d="M8.5 12l2.5 2.5 4.5-4.5"></path>',
  info: '<circle cx="12" cy="12" r="9"></circle><path d="M12 11v5.5"></path><path d="M12 7.5h.01"></path>',
};
const icon = (name, size = 20, sw = 2) =>
  `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round" style="display:block;flex-shrink:0;" aria-hidden="true">${ICONS[name]}</svg>`;

const doc = (body, bg = '#F5F7FA') => `<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&amp;display=swap">
  <style>
    * { box-sizing: border-box; }
    body { margin: 0; background: ${bg}; color: #0F172A; font-family: "Plus Jakarta Sans", system-ui, -apple-system, "Segoe UI", sans-serif; -webkit-font-smoothing: antialiased; }
    a { color: #1B3A66; } a:hover { color: #0B1F3A; }
  </style>
</helmet>
${body}
</x-dc>
</body>
</html>
`;

// ---------- Components ----------

const phone = (inner) =>
  `<div style="position:relative;display:flex;flex-direction:column;width:360px;height:800px;overflow:hidden;background:#F5F7FA;">${inner}</div>`;

const scroll = (inner, { gap = 16, pad = '4px 16px 16px' } = {}) =>
  `<div style="flex-grow:1;min-height:0;overflow:hidden;display:flex;flex-direction:column;gap:${gap}px;padding:${pad};">${inner}</div>`;

const appBar = (title, { back = true } = {}) =>
  `<div style="display:flex;align-items:center;gap:4px;min-height:64px;padding:8px 16px 8px ${back ? 4 : 16}px;">${
    back ? `<div style="flex-shrink:0;display:flex;align-items:center;justify-content:center;width:48px;height:48px;border-radius:12px;color:#0B1F3A;">${icon('back', 24)}</div>` : ''
  }<div style="${t(20, 28)}font-weight:700;color:#0B1F3A;">${title}</div></div>`;

const STEPS = ['Recipient', 'Amount', 'Confirm'];
const stepper = (n) =>
  `<div style="display:flex;flex-direction:column;gap:8px;padding:0 16px 12px;"><div style="${t(12, 16)}font-weight:600;color:#475569;">Step ${n} of 3 · ${STEPS[n - 1]}</div><div style="display:grid;grid-template-columns:repeat(3, minmax(0, 1fr));gap:6px;">${[1, 2, 3]
    .map((i) => `<div style="height:4px;border-radius:999px;background:${i <= n ? '#1B3A66' : '#E2E8F0'};"></div>`)
    .join('')}</div></div>`;

function btn(kind, label, { ic, disabled = false } = {}) {
  const isText = kind === 'text';
  const base = `display:flex;align-items:center;justify-content:center;gap:8px;min-height:${isText ? 48 : 52}px;padding:${isText ? '0 12px' : '12px 20px'};border-radius:12px;text-align:center;`;
  let look = 'color:#1B3A66;';
  if (disabled) look = 'background:#E2E8F0;color:#64748B;';
  else if (kind === 'primary') look = 'background:#C9A227;color:#0B1F3A;';
  else if (kind === 'secondary') look = 'background:#FFFFFF;color:#0B1F3A;border:1.5px solid #0B1F3A;';
  const type = isText ? `${t(14, 20)}font-weight:600;` : `${t(16, 24)}font-weight:700;`;
  return `<div style="${base}${look}${type}">${ic ? icon(ic, 20) : ''}<span>${label}</span></div>`;
}

const bottomBar = (...children) =>
  `<div style="flex-shrink:0;display:flex;flex-direction:column;gap:8px;padding:12px 16px 16px;background:#FFFFFF;border-top:1px solid #E2E8F0;">${children.join('')}</div>`;

function input({ label, value, leading, trailing, state = 'default', helper, counter }) {
  const border =
    state === 'error' ? 'border:2px solid #B91C1C;' : state === 'focused' ? 'border:2px solid #1B3A66;' : 'border:1px solid #CBD5E1;';
  const helperColor = state === 'error' ? '#B91C1C' : '#475569';
  const helperRow =
    helper || counter
      ? `<div style="display:flex;justify-content:space-between;align-items:flex-start;gap:8px;${t(12, 16)}color:${helperColor};"><div style="display:flex;align-items:flex-start;gap:4px;">${
          state === 'error' ? icon('alert', 16) : ''
        }<span>${helper || ''}</span></div>${counter ? `<span style="${NUM}flex-shrink:0;">${counter}</span>` : ''}</div>`
      : '';
  return `<div style="display:flex;flex-direction:column;gap:8px;"><div style="${t(14, 20)}font-weight:600;color:#0F172A;">${label}</div><div style="display:flex;align-items:center;gap:12px;min-height:56px;padding:0 16px;border-radius:12px;background:#FFFFFF;${border}">${
    leading ? `<span style="display:flex;color:#475569;">${icon(leading, 20)}</span>` : ''
  }<div style="flex-grow:1;${t(16, 24)}color:#0F172A;${NUM}">${value}</div>${
    trailing ? `<span style="display:flex;color:#475569;">${icon(trailing, 20)}</span>` : ''
  }</div>${helperRow}</div>`;
}

function amountField({ value, state = 'focused', helper, label = 'Amount' }) {
  const border = state === 'error' ? '2px solid #B91C1C' : '2px solid #1B3A66';
  const color = state === 'error' ? '#B91C1C' : '#475569';
  return `<div style="display:flex;flex-direction:column;gap:8px;"><div style="${t(14, 20)}font-weight:600;">${label}</div><div style="display:flex;align-items:center;min-height:80px;padding:12px 16px;border-radius:12px;background:#FFFFFF;border:${border};"><div style="${t(32, 40)}font-weight:800;${NUM}color:#0B1F3A;letter-spacing:-0.5px;">${value}</div></div><div style="display:flex;align-items:flex-start;gap:4px;${t(12, 16)}color:${color};${NUM}">${
    state === 'error' ? icon('alert', 16) : ''
  }<span>${helper}</span></div></div>`;
}

const quickChips = (labels, selected) =>
  `<div style="display:flex;flex-wrap:wrap;gap:8px;">${labels
    .map((l) => {
      const on = l === selected;
      return `<div style="display:flex;align-items:center;min-height:44px;padding:0 16px;border-radius:999px;${
        on ? 'background:#0B1F3A;color:#FFFFFF;border:1px solid #0B1F3A;' : 'background:#FFFFFF;color:#0F172A;border:1px solid #CBD5E1;'
      }${t(14, 20)}font-weight:600;${NUM}">${l}</div>`;
    })
    .join('')}</div>`;

const CHIP = {
  success: ['#DCFCE7', '#15803D', 'check'],
  pending: ['#FEF3C7', '#B45309', 'clock'],
  failed: ['#FEE2E2', '#B91C1C', 'alert'],
};
const chip = (kind, label) => {
  const [bg, fg, ic] = CHIP[kind];
  return `<div style="display:inline-flex;align-items:center;gap:4px;min-height:24px;padding:2px 8px;border-radius:999px;background:${bg};color:${fg};${t(12, 16)}font-weight:600;white-space:nowrap;">${icon(ic, 12, 2.5)}<span>${label}</span></div>`;
};

const avatar = ({ ic, initials, bg = '#E8EDF5', fg = '#1B3A66' }) =>
  `<div style="flex-shrink:0;display:flex;align-items:center;justify-content:center;width:40px;height:40px;border-radius:999px;background:${bg};color:${fg};font-size:14px;line-height:20px;font-weight:700;">${ic ? icon(ic, 20) : initials}</div>`;

const AV = {
  send: { ic: 'send' },
  save: { ic: 'target', bg: '#FBF3D5', fg: '#8A6D0F' },
  receive: { ic: 'receive', bg: '#DCFCE7', fg: '#15803D' },
  airtime: { ic: 'phone' },
};

function tile({ av, title, meta, amount, amountColor = '#0F172A', chipHtml = '' }) {
  const amt = `<div style="${t(14, 20)}font-weight:700;${NUM}color:${amountColor};white-space:nowrap;">${amount}</div>`;
  if (SCALE > 1) {
    return `<div style="display:flex;align-items:flex-start;gap:12px;padding:12px 16px;">${avatar(av)}<div style="flex-grow:1;min-width:0;display:flex;flex-direction:column;gap:4px;"><div style="${t(14, 20)}font-weight:600;">${title}</div><div style="${t(12, 16)}color:#475569;">${meta}</div><div style="display:flex;flex-wrap:wrap;align-items:center;gap:8px;">${amt}${chipHtml}</div></div></div>`;
  }
  return `<div style="display:flex;align-items:center;gap:12px;min-height:64px;padding:12px 16px;">${avatar(av)}<div style="flex-grow:1;min-width:0;display:flex;flex-direction:column;gap:2px;"><div style="${t(14, 20)}font-weight:600;">${title}</div><div style="${t(12, 16)}color:#475569;">${meta}</div></div><div style="flex-shrink:0;display:flex;flex-direction:column;align-items:flex-end;gap:4px;">${amt}${chipHtml}</div></div>`;
}
const divider = `<div style="height:1px;margin-left:68px;background:#EEF2F6;"></div>`;
const list = (items) =>
  `<div style="display:flex;flex-direction:column;border-radius:16px;background:#FFFFFF;border:1px solid #E2E8F0;">${items.join(divider)}</div>`;

const card = (inner, gap = 12) =>
  `<div style="display:flex;flex-direction:column;gap:${gap}px;padding:16px;border-radius:16px;background:#FFFFFF;border:1px solid #E2E8F0;">${inner}</div>`;
const hr = `<div style="height:1px;background:#E2E8F0;"></div>`;

const kv = (label, value, { strong = false } = {}) =>
  `<div style="display:flex;flex-wrap:wrap;justify-content:space-between;align-items:center;gap:4px 16px;"><div style="${t(14, 20)}color:#475569;">${label}</div><div style="${
    strong ? `${t(16, 24)}font-weight:800;` : `${t(14, 20)}font-weight:600;`
  }${NUM}text-align:right;color:#0F172A;">${value}</div></div>`;
const kvChip = (label, chipHtml) =>
  `<div style="display:flex;justify-content:space-between;align-items:center;gap:16px;"><div style="${t(14, 20)}color:#475569;">${label}</div>${chipHtml}</div>`;

const note = (ic, body, { bg = '#E8EDF5', fg = '#1B3A66' } = {}) =>
  `<div style="display:flex;align-items:flex-start;gap:12px;padding:12px 16px;border-radius:12px;background:${bg};"><span style="display:flex;color:${fg};">${icon(ic, 20)}</span><div style="${t(14, 20)}color:#0F172A;">${body}</div></div>`;

const inlineHint = (ic, body) =>
  `<div style="display:flex;align-items:flex-start;gap:8px;${t(12, 16)}color:#475569;"><span style="display:flex;">${icon(ic, 16)}</span><span>${body}</span></div>`;

const offlineBanner = () =>
  `<div style="flex-shrink:0;display:flex;align-items:flex-start;gap:12px;padding:12px 16px;background:#334155;color:#FFFFFF;"><span style="display:flex;">${icon('wifiOff', 20)}</span><div style="display:flex;flex-direction:column;gap:2px;"><div style="${t(14, 20)}font-weight:600;">You're offline</div><div style="${t(14, 20)}">Transfers and savings will go out once you reconnect. No data? Dial *894#.</div></div></div>`;

const sectionHeader = (title, action = '') =>
  `<div style="display:flex;align-items:center;justify-content:space-between;gap:8px;min-height:48px;"><div style="${t(16, 24)}font-weight:700;color:#0B1F3A;">${title}</div>${action}</div>`;
const textLink = (label) =>
  `<div style="flex-shrink:0;display:flex;align-items:center;min-height:48px;padding:0 4px;${t(14, 20)}font-weight:600;color:#1B3A66;">${label}</div>`;

function bottomNav(active) {
  const items = [
    ['home', 'Home'],
    ['target', 'Save'],
    ['user', 'Profile'],
  ];
  return `<div style="flex-shrink:0;display:grid;grid-template-columns:repeat(3, minmax(0, 1fr));min-height:72px;background:#FFFFFF;border-top:1px solid #E2E8F0;">${items
    .map(([ic, label]) => {
      const on = label === active;
      return `<div style="display:flex;flex-direction:column;align-items:center;justify-content:center;gap:4px;padding:8px 0;color:${on ? '#0B1F3A' : '#64748B'};"><div style="display:flex;align-items:center;justify-content:center;width:56px;height:32px;border-radius:999px;background:${
        on ? '#FBF3D5' : 'transparent'
      };">${icon(ic, 24)}</div><div style="${t(12, 16)}font-weight:${on ? 700 : 500};">${label}</div></div>`;
    })
    .join('')}</div>`;
}

const bar = (pct, pendingPct = 0) =>
  `<div style="display:flex;height:8px;border-radius:999px;background:#E2E8F0;overflow:hidden;"><div style="width:${pct}%;height:8px;background:#1B3A66;"></div>${
    pendingPct
      ? `<div style="width:${pendingPct}%;height:8px;background:repeating-linear-gradient(45deg, #C9A227 0px, #C9A227 4px, #E6CF7A 4px, #E6CF7A 8px);"></div>`
      : ''
  }</div>`;

const statusHero = ({ ic, bg, fg, title, body }) =>
  `<div style="display:flex;flex-direction:column;align-items:center;gap:12px;padding:24px 8px 8px;text-align:center;"><div style="display:flex;align-items:center;justify-content:center;width:72px;height:72px;border-radius:999px;background:${bg};color:${fg};">${icon(ic, 36, 2.25)}</div><div style="${t(24, 32)}font-weight:800;color:#0B1F3A;text-wrap:balance;">${title}</div><div style="${t(16, 24)}color:#475569;text-wrap:pretty;">${body}</div></div>`;

// ---------- Wallet home ----------

const greeting = () =>
  `<div style="flex-shrink:0;display:flex;align-items:center;justify-content:space-between;gap:12px;padding:16px 16px 8px;"><div style="display:flex;flex-direction:column;"><div style="${t(14, 20)}color:#475569;">Good evening,</div><div style="${t(20, 28)}font-weight:700;color:#0B1F3A;">Folake</div></div><div style="flex-shrink:0;display:flex;align-items:center;justify-content:center;width:40px;height:40px;border-radius:999px;background:#1B3A66;color:#FFFFFF;font-size:14px;line-height:20px;font-weight:700;">FA</div></div>`;

function balanceCard({ offline = false } = {}) {
  const large = SCALE > 1;
  const label = offline ? 'Available balance' : 'NovaWallet balance';
  const naira = offline ? '₦216,350' : '₦248,350';
  const caption = offline ? '₦32,000.00 pending · Last updated 21:58' : 'Updated 22:04 · Pull down to refresh';
  const grow = large ? '' : 'flex-grow:1;flex-basis:0;';
  return `<div style="flex-shrink:0;display:flex;flex-direction:column;gap:16px;padding:20px;border-radius:20px;background:#0B1F3A;color:#FFFFFF;">
<div style="display:flex;align-items:center;justify-content:space-between;gap:8px;"><div style="${t(14, 20)}font-weight:500;color:#A9B8CF;">${label}</div><div style="flex-shrink:0;display:flex;align-items:center;justify-content:center;width:48px;height:48px;margin:-12px;color:#A9B8CF;">${icon('eye', 20)}</div></div>
<div style="display:flex;flex-wrap:wrap;align-items:baseline;${NUM}font-weight:800;letter-spacing:-0.5px;"><span style="${t(32, 40)}">${naira}</span><span style="${t(20, 28)}">.75</span></div>
<div style="${t(12, 16)}color:#A9B8CF;${NUM}">${caption}</div>
<div style="display:flex;flex-direction:${large ? 'column' : 'row'};gap:12px;">
<div style="${grow}display:flex;align-items:center;justify-content:center;gap:8px;min-height:48px;padding:8px 12px;border-radius:12px;background:#C9A227;color:#0B1F3A;${t(14, 20)}font-weight:700;">${icon('send', 20)}<span>Send</span></div>
<div style="${grow}display:flex;align-items:center;justify-content:center;gap:8px;min-height:48px;padding:8px 12px;border-radius:12px;border:1.5px solid #A9B8CF;color:#FFFFFF;${t(14, 20)}font-weight:600;">${icon('target', 20)}<span>Save</span></div>
</div>
</div>`;
}

const novaSaveTile = () =>
  `<div style="flex-shrink:0;display:flex;align-items:center;gap:12px;min-height:64px;padding:12px 16px;border-radius:16px;background:#FFFFFF;border:1px solid #E2E8F0;">${avatar(AV.save)}<div style="flex-grow:1;min-width:0;display:flex;flex-direction:column;gap:2px;"><div style="${t(14, 20)}font-weight:600;">NovaSave</div><div style="${t(12, 16)}color:#475569;${NUM}">₦412,500.00 saved across 3 goals</div></div><span style="display:flex;color:#64748B;">${icon('chevronRight', 20)}</span></div>`;

function homeScreen({ offline = false } = {}) {
  const items = offline
    ? [
        tile({ av: AV.send, title: 'Aisha Bello', meta: 'Kuda · Today, 22:06', amount: '−₦12,000.00', chipHtml: chip('pending', 'Pending') }),
        tile({ av: AV.save, title: 'NovaSave · New laptop', meta: 'Contribution · Today, 22:10', amount: '−₦20,000.00', chipHtml: chip('pending', 'Pending') }),
        tile({ av: AV.send, title: 'Emeka Nwosu', meta: 'Zenith Bank · Not sent', amount: '₦45,000.00', amountColor: '#475569', chipHtml: chip('failed', 'Failed') }),
        tile({ av: AV.send, title: 'Chiamaka Obi', meta: 'GTBank · Today, 21:14', amount: '−₦15,000.00' }),
        tile({ av: AV.receive, title: 'Tunde Bakare', meta: 'Access Bank · Yesterday, 18:40', amount: '+₦50,000.00', amountColor: '#15803D' }),
      ]
    : [
        tile({ av: AV.send, title: 'Chiamaka Obi', meta: 'GTBank · Today, 21:14', amount: '−₦15,000.00' }),
        tile({ av: AV.save, title: 'NovaSave · Rent 2027', meta: 'Contribution · Today, 08:02', amount: '−₦5,000.00' }),
        tile({ av: AV.receive, title: 'Tunde Bakare', meta: 'Access Bank · Yesterday, 18:40', amount: '+₦50,000.00', amountColor: '#15803D' }),
        tile({ av: AV.airtime, title: 'MTN Airtime', meta: '0803 ••• 4412 · Yesterday, 12:10', amount: '−₦2,000.00' }),
        tile({ av: AV.receive, title: 'Brightpath Ltd', meta: 'Salary · 12 Sep', amount: '+₦320,000.00', amountColor: '#15803D' }),
        tile({ av: AV.send, title: 'Aisha Bello', meta: 'Kuda · 11 Sep', amount: '−₦7,500.00' }),
      ];
  return phone(
    `${offline ? offlineBanner() : ''}${greeting()}${scroll(
      `${balanceCard({ offline })}${novaSaveTile()}${sectionHeader('Recent transactions', textLink('See all'))}${list(items)}`,
      { pad: '0 16px 16px' },
    )}${bottomNav('Home')}`,
  );
}

// ---------- Send money ----------

const recentRecipients = () =>
  `${sectionHeader('Recent recipients')}${list([
    tile({ av: { initials: 'TB' }, title: 'Tunde Bakare', meta: 'Access Bank · ••••4821', amount: '' }),
    tile({ av: { initials: 'AB' }, title: 'Aisha Bello', meta: 'Kuda · ••••0937', amount: '' }),
    tile({ av: { initials: 'EN' }, title: 'Emeka Nwosu', meta: 'Zenith Bank · ••••5510', amount: '' }),
  ])}`;

function sendRecipient({ error = false } = {}) {
  const account = error
    ? input({ label: 'Account number', value: '01234567', state: 'error', helper: 'Enter all 10 digits of the account number (8 entered).', counter: '8/10' })
    : input({ label: 'Account number', value: '0123456789', counter: '10/10' });
  const resolved = error
    ? ''
    : `<div style="display:flex;align-items:center;gap:12px;padding:12px 16px;border-radius:12px;background:#DCFCE7;"><div style="flex-shrink:0;display:flex;align-items:center;justify-content:center;width:32px;height:32px;border-radius:999px;background:#15803D;color:#FFFFFF;">${icon('check', 18, 2.5)}</div><div style="display:flex;flex-direction:column;gap:2px;"><div style="${t(12, 16)}color:#475569;">Account name</div><div style="${t(14, 20)}font-weight:700;color:#0F172A;">CHIAMAKA ADAEZE OBI</div></div></div>`;
  return phone(
    `${appBar('Send money')}${stepper(1)}${scroll(
      `${input({ label: 'Bank', value: 'GTBank', leading: 'bank', trailing: 'chevronDown' })}${account}${resolved}${recentRecipients()}`,
    )}${bottomBar(btn('primary', 'Continue', { disabled: error }))}`,
  );
}

const recipientSummary = () =>
  `<div style="display:flex;flex-wrap:wrap;align-items:center;gap:4px 12px;padding:12px 16px;border-radius:16px;background:#FFFFFF;border:1px solid #E2E8F0;">${avatar({ initials: 'CO' })}<div style="flex:1 1 160px;min-width:0;display:flex;flex-direction:column;gap:2px;"><div style="${t(14, 20)}font-weight:600;">Chiamaka Adaeze Obi</div><div style="${t(12, 16)}color:#475569;${NUM}">GTBank · 0123456789</div></div>${textLink('Change')}</div>`;

function sendAmount({ error = false } = {}) {
  const field = error
    ? amountField({ value: '₦300,000.00', state: 'error', helper: 'This is more than your available balance of ₦248,350.75.' })
    : amountField({ value: '₦15,000.00', helper: 'Available balance: ₦248,350.75' });
  return phone(
    `${appBar('Send money')}${stepper(2)}${scroll(
      `${recipientSummary()}${field}${quickChips(['₦1,000', '₦5,000', '₦10,000'])}${input({ label: 'Narration (optional)', value: 'Rent contribution' })}${inlineHint(
        'info',
        'Tier 1 accounts can send up to ₦50,000.00 per transfer.',
      )}`,
    )}${bottomBar(btn('primary', 'Continue', { disabled: error }))}`,
  );
}

function sendConfirm() {
  const hero = `<div style="display:flex;flex-direction:column;align-items:center;gap:4px;padding:4px 0 8px;text-align:center;"><div style="${t(14, 20)}color:#475569;">You're sending</div><div style="${t(32, 40)}font-weight:800;${NUM}color:#0B1F3A;letter-spacing:-0.5px;">₦15,000.00</div><div style="${t(14, 20)}color:#0F172A;">to Chiamaka Adaeze Obi</div></div>`;
  const summary = card(
    `${kv('Bank', 'GTBank')}${kv('Account number', '0123456789')}${kv('Narration', 'Rent contribution')}${hr}${kv('Amount', '₦15,000.00')}${kv('Transfer fee', '₦0.00')}${kv(
      'Total',
      '₦15,000.00',
      { strong: true },
    )}${hr}${kv('Reference', `<span style="${MONO}">NP-7F3A-91C2</span>`)}`,
  );
  return phone(
    `${appBar('Send money')}${stepper(3)}${scroll(
      `${hero}${summary}${note('shield', 'This transfer has a unique reference, so it can only go through once — even if your connection drops and we try again.')}`,
    )}${bottomBar(btn('primary', 'Confirm and send ₦15,000.00'), btn('text', 'Cancel'))}`,
  );
}

function sendSent() {
  return phone(
    `${scroll(
      `${statusHero({ ic: 'check', bg: '#DCFCE7', fg: '#15803D', title: 'Transfer sent', body: '₦15,000.00 is on its way to Chiamaka Adaeze Obi at GTBank.' })}${card(
        `${kvChip('Status', chip('success', 'Sent'))}${kv('Reference', `<span style="${MONO}">NP-7F3A-91C2</span>`)}${kv('Date', '15 Sep 2026, 22:04')}`,
      )}`,
      { pad: '32px 16px 16px' },
    )}${bottomBar(btn('primary', 'Done'), btn('secondary', 'Share receipt'))}`,
  );
}

function sendQueued() {
  return phone(
    `${offlineBanner()}${scroll(
      `${statusHero({
        ic: 'clock',
        bg: '#FEF3C7',
        fg: '#B45309',
        title: 'Pending — will send when back online',
        body: "You're offline, so we've saved this transfer on your phone. It will be sent once, automatically, when you reconnect — even if you close the app.",
      })}${card(
        `${kvChip('Status', chip('pending', 'Pending'))}${kv('To', 'Chiamaka Adaeze Obi')}${kv('Amount', '₦15,000.00')}${kv('Reference', `<span style="${MONO}">NP-7F3A-91C2</span>`)}${kv(
          'Saved',
          '15 Sep 2026, 22:06',
        )}`,
      )}${inlineHint('info', '₦15,000.00 is held from your available balance until it goes through.')}`,
      { pad: '8px 16px 16px' },
    )}${bottomBar(btn('primary', 'Back to home'), btn('secondary', 'View activity'))}`,
  );
}

// ---------- NovaSave ----------

const goalCard = ({ name, date, saved, target, pct, width }) =>
  card(
    `<div style="display:flex;justify-content:space-between;align-items:flex-start;gap:12px;"><div style="${t(16, 24)}font-weight:700;color:#0B1F3A;">${name}</div><div style="${t(14, 20)}font-weight:700;color:#1B3A66;${NUM}">${pct}%</div></div><div style="display:flex;align-items:center;gap:6px;${t(12, 16)}color:#475569;">${icon(
      'calendar',
      16,
    )}<span>Target: ${date}</span></div>${bar(width)}<div style="display:flex;flex-wrap:wrap;gap:4px;${t(14, 20)}${NUM}"><span style="font-weight:600;color:#0F172A;">${saved} saved</span><span style="color:#475569;">of ${target}</span></div>`,
  );

function saveGoals() {
  const summary = `<div style="flex-shrink:0;display:flex;flex-direction:column;gap:4px;padding:20px;border-radius:20px;background:#0B1F3A;color:#FFFFFF;"><div style="${t(14, 20)}font-weight:500;color:#A9B8CF;">Total saved</div><div style="${t(32, 40)}font-weight:800;${NUM}letter-spacing:-0.5px;">₦412,500.00</div><div style="${t(12, 16)}color:#A9B8CF;">Across 3 goals</div></div>`;
  const newGoal = `<div style="flex-shrink:0;display:flex;align-items:center;gap:6px;min-height:44px;padding:0 14px;border-radius:12px;border:1.5px solid #0B1F3A;background:#FFFFFF;color:#0B1F3A;${t(14, 20)}font-weight:700;">${icon('plus', 18)}<span>New goal</span></div>`;
  return phone(
    `<div style="flex-shrink:0;padding:20px 16px 12px;"><div style="${t(24, 32)}font-weight:800;color:#0B1F3A;">NovaSave</div></div>${scroll(
      `${summary}${sectionHeader('Your goals', newGoal)}${goalCard({ name: 'Rent 2027', date: '31 Jan 2027', saved: '₦285,000.00', target: '₦600,000.00', pct: 47, width: 47.5 })}${goalCard({
        name: 'New laptop',
        date: '30 Nov 2026',
        saved: '₦97,500.00',
        target: '₦450,000.00',
        pct: 21,
        width: 21.67,
      })}${goalCard({ name: 'Emergency fund', date: '31 Dec 2026', saved: '₦30,000.00', target: '₦200,000.00', pct: 15, width: 15 })}`,
      { pad: '0 16px 16px' },
    )}${bottomNav('Save')}`,
  );
}

function saveCreate() {
  return phone(
    `${appBar('Create a goal')}${scroll(
      `${input({ label: 'Goal name', value: 'School fees', counter: '11/40' })}${input({ label: 'Target amount', value: '₦350,000.00', state: 'focused' })}${input({
        label: 'Target date',
        value: '15 Jan 2027',
        leading: 'calendar',
        trailing: 'chevronDown',
      })}${note('target', 'Save about <strong>₦87,500.00 a month</strong> to reach ₦350,000.00 by 15 Jan 2027.', { bg: '#FBF3D5', fg: '#8A6D0F' })}`,
      { gap: 20, pad: '8px 16px 16px' },
    )}${bottomBar(btn('primary', 'Create goal'))}`,
  );
}

const goalProgress = ({ saved, of, pct, width, pendingWidth = 0, date, legend = '' }) =>
  card(
    `<div style="display:flex;flex-direction:column;gap:2px;"><div style="${t(28, 36)}font-weight:800;${NUM}color:#0B1F3A;letter-spacing:-0.5px;">${saved}</div><div style="${t(14, 20)}color:#475569;${NUM}">saved of ${of}</div></div>${bar(
      width,
      pendingWidth,
    )}${legend || `<div style="display:flex;justify-content:space-between;gap:12px;${t(14, 20)}"><span style="font-weight:700;color:#1B3A66;${NUM}">${pct}% saved</span><span style="color:#475569;">Target: ${date}</span></div>`}`,
  );

function saveContribute() {
  const base = `${appBar('Rent 2027')}${scroll(
    `${goalProgress({ saved: '₦285,000.00', of: '₦600,000.00', pct: 47, width: 47.5, date: '31 Jan 2027' })}${sectionHeader('Contributions')}${list([
      tile({ av: AV.save, title: '₦5,000.00', meta: 'Today, 08:02', amount: '', chipHtml: chip('success', 'Added') }),
      tile({ av: AV.save, title: '₦20,000.00', meta: '1 Sep 2026', amount: '', chipHtml: chip('success', 'Added') }),
      tile({ av: AV.save, title: '₦10,000.00', meta: '15 Aug 2026', amount: '', chipHtml: chip('success', 'Added') }),
    ])}`,
  )}`;
  const sheet = `<div style="position:absolute;left:0;right:0;bottom:0;display:flex;flex-direction:column;gap:16px;padding:12px 16px 16px;border-radius:24px 24px 0 0;background:#FFFFFF;">
<div style="align-self:center;width:32px;height:4px;border-radius:999px;background:#CBD5E1;"></div>
<div style="display:flex;flex-direction:column;gap:4px;"><div style="${t(20, 28)}font-weight:800;color:#0B1F3A;">Add to Rent 2027</div><div style="${t(14, 20)}color:#475569;${NUM}">From NovaWallet · Available ₦248,350.75</div></div>
${amountField({ value: '₦5,000.00', helper: 'Moves from your wallet to this goal.' })}
${quickChips(['₦2,000', '₦5,000', '₦10,000'], '₦5,000')}
<div style="display:flex;flex-direction:column;gap:8px;padding:12px 16px;border-radius:12px;background:#F5F7FA;"><div style="display:flex;justify-content:space-between;gap:12px;${t(12, 16)}color:#475569;"><span>After this</span><span style="font-weight:700;color:#1B3A66;">48%</span></div><div style="${t(14, 20)}font-weight:600;${NUM}">₦290,000.00 of ₦600,000.00</div>${bar(48.33)}</div>
${btn('primary', 'Add ₦5,000.00')}
</div>`;
  return phone(`${base}<div style="position:absolute;inset:0;background:rgba(11,31,58,0.56);"></div>${sheet}`);
}

function saveGoalPending() {
  const legend = `<div style="display:flex;flex-wrap:wrap;gap:8px 20px;${t(12, 16)}${NUM}"><div style="display:flex;align-items:center;gap:6px;"><span style="width:12px;height:12px;border-radius:3px;background:#1B3A66;"></span><span style="color:#0F172A;font-weight:600;">Saved 21%</span></div><div style="display:flex;align-items:center;gap:6px;"><span style="width:12px;height:12px;border-radius:3px;background:repeating-linear-gradient(45deg, #C9A227 0px, #C9A227 3px, #E6CF7A 3px, #E6CF7A 6px);"></span><span style="color:#0F172A;font-weight:600;">Pending ₦20,000.00</span></div></div>`;
  return phone(
    `${offlineBanner()}${appBar('New laptop')}${scroll(
      `${goalProgress({ saved: '₦97,500.00', of: '₦450,000.00', width: 21.67, pendingWidth: 4.44, legend })}${note(
        'clock',
        "₦20,000.00 is saved on your phone and will be added once, automatically, when you're back online. It isn't counted as saved yet.",
        { bg: '#FEF3C7', fg: '#B45309' },
      )}${sectionHeader('Contributions')}${list([
        tile({ av: AV.save, title: '₦20,000.00', meta: 'Today, 22:10', amount: '', chipHtml: chip('pending', 'Pending') }),
        tile({ av: AV.save, title: '₦12,500.00', meta: '2 Sep 2026', amount: '', chipHtml: chip('success', 'Added') }),
        tile({ av: AV.save, title: '₦85,000.00', meta: '1 Aug 2026', amount: '', chipHtml: chip('success', 'Added') }),
      ])}`,
    )}${bottomBar(btn('primary', 'Add money'))}`,
  );
}

// ---------- Errors ----------

function syncFailed() {
  return phone(
    `${appBar('Transfer details')}${scroll(
      `${statusHero({ ic: 'alert', bg: '#FEE2E2', fg: '#B91C1C', title: 'Not sent', body: '₦45,000.00 to Emeka Nwosu · Zenith Bank' })}<div style="display:flex;flex-direction:column;gap:4px;padding:12px 16px;border-radius:12px;background:#FEE2E2;"><div style="${t(14, 20)}font-weight:700;color:#B91C1C;">Why it didn't go through</div><div style="${t(14, 20)}color:#0F172A;">You've reached today's transfer limit. Your balance was not debited.</div></div>${card(
        `${kvChip('Status', chip('failed', 'Failed'))}${kv('Reference', `<span style="${MONO}">NP-2C81-44D0</span>`)}${kv('Saved offline', '15 Sep 2026, 21:32')}${kv('Tried', '15 Sep 2026, 22:12')}`,
      )}${inlineHint('info', "Failed transfers are never retried automatically, so nothing will leave your wallet without you.")}`,
      { pad: '0 16px 16px' },
    )}${bottomBar(
      btn('primary', 'Try again'),
      `<div style="${t(12, 16)}color:#475569;text-align:center;">Starts a new transfer with a new reference</div>`,
    )}`,
  );
}

// ---------- Spec sheet ----------

function specs() {
  SCALE = 1;
  const section = (title, sub, inner) =>
    `<div style="display:flex;flex-direction:column;gap:16px;"><div style="display:flex;flex-direction:column;gap:4px;"><div style="font-size:24px;line-height:32px;font-weight:800;color:#0B1F3A;">${title}</div>${
      sub ? `<div style="font-size:14px;line-height:20px;color:#475569;">${sub}</div>` : ''
    }</div>${inner}</div>`;

  const swatch = (name, hexes, use) => {
    const tone =
      hexes.length === 1
        ? `<div style="height:72px;border-radius:12px;background:${hexes[0]};border:1px solid rgba(15,23,42,0.08);"></div>`
        : `<div style="display:grid;grid-template-columns:repeat(2, minmax(0, 1fr));height:72px;border-radius:12px;overflow:hidden;border:1px solid rgba(15,23,42,0.08);"><div style="background:${hexes[0]};"></div><div style="background:${hexes[1]};"></div></div>`;
    return `<div style="display:flex;flex-direction:column;gap:8px;padding:12px;border-radius:16px;background:#FFFFFF;border:1px solid #E2E8F0;">${tone}<div style="display:flex;flex-direction:column;gap:2px;"><div style="font-size:14px;line-height:20px;font-weight:700;">${name}</div><div style="font-size:13px;line-height:18px;font-weight:600;color:#1B3A66;${MONO}">${hexes.join(
      ' / ',
    )}</div><div style="font-size:12px;line-height:16px;color:#475569;">${use}</div></div></div>`;
  };
  const colours = `<div style="display:grid;grid-template-columns:repeat(6, minmax(0, 1fr));gap:16px;">${[
    ['Navy 900', ['#0B1F3A'], 'Balance card, headings, secondary button border'],
    ['Navy 700', ['#1B3A66'], 'Progress fill, focus ring, links, avatars'],
    ['Gold 500', ['#C9A227'], 'Primary button fill (Navy 900 label, 7.0:1)'],
    ['Gold tint', ['#FBF3D5'], 'Active nav indicator, savings icon well'],
    ['Navy tint', ['#E8EDF5'], 'Info notes, recipient avatars'],
    ['Background', ['#F5F7FA'], 'Screen background'],
    ['Surface', ['#FFFFFF'], 'Cards, inputs, bars, sheets'],
    ['Border', ['#E2E8F0'], 'Card borders, dividers, progress track'],
    ['Input border', ['#CBD5E1'], 'Inputs, quick chips, sheet handle'],
    ['Text primary', ['#0F172A'], 'Body and values (17.9:1 on white)'],
    ['Text secondary', ['#475569'], 'Labels, meta (7.6:1 on white)'],
    ['Text muted', ['#64748B'], 'Inactive nav, disabled label (4.8:1)'],
    ['On navy', ['#A9B8CF'], 'Secondary text on Navy 900 (8.0:1)'],
    ['Success', ['#15803D', '#DCFCE7'], 'Sent / Added, incoming amounts'],
    ['Pending', ['#B45309', '#FEF3C7'], 'Queued offline actions'],
    ['Error', ['#B91C1C', '#FEE2E2'], 'Validation, failed sync'],
    ['Offline banner', ['#334155'], 'Connectivity banner, white text (10:1)'],
    ['Scrim', ['rgba(11,31,58,0.56)'], 'Behind bottom sheets'],
  ]
    .map(([n, h, u]) => swatch(n, h, u))
    .join('')}</div>`;

  const typeRow = (token, sampleStyle, sample, spec) =>
    `<div style="display:grid;grid-template-columns:180px minmax(0, 1fr) 360px;align-items:center;gap:24px;padding:16px 20px;"><div style="font-size:14px;line-height:20px;font-weight:700;color:#0B1F3A;">${token}</div><div style="${sampleStyle}color:#0F172A;">${sample}</div><div style="font-size:13px;line-height:18px;color:#475569;${MONO}">${spec}</div></div>`;
  const type = `<div style="display:flex;flex-direction:column;border-radius:16px;background:#FFFFFF;border:1px solid #E2E8F0;">${[
    typeRow('Display', `font-size:32px;line-height:40px;font-weight:800;letter-spacing:-0.5px;${NUM}`, '₦248,350.75', '32 / 40 · ExtraBold 800 · −0.5 tracking · tabular'),
    typeRow('Headline', 'font-size:24px;line-height:32px;font-weight:800;', 'Transfer sent', '24 / 32 · ExtraBold 800'),
    typeRow('Title', 'font-size:20px;line-height:28px;font-weight:700;', 'Send money', '20 / 28 · Bold 700'),
    typeRow('Body large', 'font-size:16px;line-height:24px;font-weight:400;', '₦15,000.00 is on its way to Chiamaka.', '16 / 24 · Regular 400'),
    typeRow('Label', 'font-size:14px;line-height:20px;font-weight:600;', 'Account number', '14 / 20 · SemiBold 600'),
    typeRow('Body', 'font-size:14px;line-height:20px;font-weight:400;', 'Available balance: ₦248,350.75', '14 / 20 · Regular 400'),
    typeRow('Caption', 'font-size:12px;line-height:16px;font-weight:500;', 'GTBank · Today, 21:14', '12 / 16 · Medium 500'),
  ].join(hr)}</div>`;

  const spacing = card(
    `<div style="font-size:16px;line-height:24px;font-weight:700;color:#0B1F3A;">Spacing (dp)</div>${[4, 8, 12, 16, 20, 24, 32]
      .map(
        (s) =>
          `<div style="display:flex;align-items:center;gap:12px;"><span style="width:28px;font-size:13px;line-height:18px;${MONO}color:#475569;">${s}</span><span style="width:${s * 6}px;height:12px;border-radius:3px;background:#1B3A66;"></span></div>`,
      )
      .join('')}<div style="font-size:13px;line-height:18px;color:#475569;">Screen side padding 16 · gap between blocks 16 · card padding 16</div>`,
  );
  const radii = card(
    `<div style="font-size:16px;line-height:24px;font-weight:700;color:#0B1F3A;">Corner radius (dp)</div><div style="display:grid;grid-template-columns:repeat(3, minmax(0, 1fr));gap:12px;">${[
      ['12', 'Buttons, inputs, notes'],
      ['16', 'Cards, lists'],
      ['20', 'Balance card'],
      ['24', 'Bottom sheet (top)'],
      ['999', 'Chips, avatars, bars'],
    ]
      .map(
        ([r, u]) =>
          `<div style="display:flex;flex-direction:column;gap:6px;"><div style="height:56px;border-radius:${Math.min(Number(r), 28)}px;background:#E8EDF5;border:1.5px solid #1B3A66;"></div><div style="font-size:13px;line-height:18px;font-weight:700;${MONO}">${r}</div><div style="font-size:12px;line-height:16px;color:#475569;">${u}</div></div>`,
      )
      .join('')}</div>`,
  );
  const elevation = card(
    `<div style="font-size:16px;line-height:24px;font-weight:700;color:#0B1F3A;">Elevation &amp; touch</div>${[
      'No drop shadows. Cards use a 1dp #E2E8F0 border instead, which is cheaper to draw on low-end Android.',
      'Bottom sheets sit on a Navy 900 scrim at 56% opacity.',
      'Every tappable element is at least 48×48dp (quick chips 44dp high with a 48dp touch area).',
      'Status is never shown by colour alone: chips always pair an icon with a word.',
      'Text containers use min-height, never a fixed height, so layouts grow with the system font size (checked at 200%).',
    ]
      .map(
        (s) =>
          `<div style="display:flex;gap:8px;font-size:14px;line-height:20px;color:#334155;"><span style="flex-shrink:0;width:6px;height:6px;margin-top:7px;border-radius:999px;background:#C9A227;"></span><span>${s}</span></div>`,
      )
      .join('')}`,
  );

  const comp = (title, sample, specsList, sampleBg = '#F5F7FA') =>
    `<div style="display:flex;flex-direction:column;gap:16px;padding:20px;border-radius:16px;background:#FFFFFF;border:1px solid #E2E8F0;"><div style="font-size:16px;line-height:24px;font-weight:700;color:#0B1F3A;">${title}</div><div style="display:flex;flex-direction:column;justify-content:center;gap:12px;min-height:120px;padding:20px;border-radius:12px;background:${sampleBg};">${sample}</div><div style="display:flex;flex-direction:column;gap:6px;">${specsList
      .map(
        (s) =>
          `<div style="display:flex;gap:8px;font-size:13px;line-height:18px;color:#334155;"><span style="flex-shrink:0;width:6px;height:6px;margin-top:6px;border-radius:999px;background:#C9A227;"></span><span>${s}</span></div>`,
      )
      .join('')}</div></div>`;

  const components = `<div style="display:grid;grid-template-columns:repeat(3, minmax(0, 1fr));gap:16px;align-items:start;">${[
    comp('Primary button', `${btn('primary', 'Confirm and send')}${btn('primary', 'Continue', { disabled: true })}`, [
      'Min height 52 · radius 12 · padding 12 / 20',
      'Fill Gold 500 #C9A227 · label 16/24 Bold, Navy 900 #0B1F3A (7.0:1)',
      'Disabled: fill #E2E8F0 · label #64748B',
      'One primary button per screen, pinned in the bottom bar',
    ]),
    comp('Secondary & text buttons', `${btn('secondary', 'Share receipt')}${btn('text', 'Cancel')}`, [
      'Secondary: min height 52 · radius 12 · 1.5 border Navy 900 · fill white · label 16/24 Bold Navy 900',
      'Text: min height 48 · padding 0 / 12 · label 14/20 SemiBold Navy 700 #1B3A66',
    ]),
    comp('Bottom bar', bottomBar(btn('primary', 'Continue')), [
      'Fill white · 1 top border #E2E8F0 · padding 12 / 16 / 16 · gap 8',
      'Stays pinned while the content above scrolls',
    ]),
    comp(
      'Text input',
      `${input({ label: 'Account number', value: '0123456789', counter: '10/10' })}${input({ label: 'Target amount', value: '₦350,000.00', state: 'focused' })}${input({
        label: 'Account number',
        value: '01234567',
        state: 'error',
        helper: 'Enter all 10 digits (8 entered).',
        counter: '8/10',
      })}`,
      [
        'Min height 56 · radius 12 · padding 0 / 16 · value 16/24 Regular',
        'Border: default 1 #CBD5E1 → focused 2 Navy 700 → error 2 #B91C1C',
        'Label 14/20 SemiBold, 8 above · helper & counter 12/16, 8 below',
        'Error helper starts with a 16dp alert icon',
      ],
    ),
    comp('Amount input', amountField({ value: '₦15,000.00', helper: 'Available balance: ₦248,350.75' }), [
      'Min height 80 · radius 12 · padding 12 / 16 · 2 border Navy 700 while focused',
      'Value 32/40 ExtraBold · tabular figures · Navy 900',
      'Text is parsed to whole kobo (no decimals stored)',
    ]),
    comp('Quick-amount chips', quickChips(['₦2,000', '₦5,000', '₦10,000'], '₦5,000'), [
      'Min height 44 · pill · padding 0 / 16 · gap 8, wraps to new lines',
      'Default: white · 1 border #CBD5E1 · label 14/20 SemiBold',
      'Selected: fill Navy 900 · label white',
    ]),
    comp('Status chips', `<div style="display:flex;flex-wrap:wrap;gap:8px;">${chip('success', 'Sent')}${chip('pending', 'Pending')}${chip('failed', 'Failed')}</div>`, [
      'Min height 24 · pill · padding 2 / 8 · icon 12 + gap 4 · label 12/16 SemiBold',
      'Sent #15803D on #DCFCE7 (4.7:1)',
      'Pending #B45309 on #FEF3C7 (5.3:1)',
      'Failed #B91C1C on #FEE2E2 (5.4:1)',
    ]),
    comp('Card', card(`${kv('Amount', '₦15,000.00')}${kv('Transfer fee', '₦0.00')}${hr}${kv('Total', '₦15,000.00', { strong: true })}`), [
      'Fill white · radius 16 · padding 16 · 1 border #E2E8F0 · gap 12',
      'Key/value rows: label 14/20 #475569 · value 14/20 SemiBold, right-aligned, tabular',
      'Totals: 16/24 ExtraBold · dividers 1 #E2E8F0',
    ]),
    comp('Transaction tile', list([tile({ av: AV.send, title: 'Aisha Bello', meta: 'Kuda · Today, 22:06', amount: '−₦12,000.00', chipHtml: chip('pending', 'Pending') })]), [
      'Min height 64 · padding 12 / 16 · gap 12',
      'Avatar 40 circle · icon 20 (send Navy tint, save Gold tint, incoming Success tint)',
      'Title 14/20 SemiBold · meta 12/16 #475569',
      'Amount 14/20 Bold tabular · incoming shows + and Success colour',
      'Divider 1 #EEF2F6, inset 68 from the left',
    ]),
    comp('Offline banner', offlineBanner(), [
      'Full width · padding 12 / 16 · fill #334155 · gap 12',
      'Icon 20 white · title 14/20 SemiBold · body 14/20 Regular white (10:1)',
      'Shown at the top of every screen while offline',
    ]),
    comp('Progress bar', `${bar(47.5)}${bar(21.67, 4.44)}`, [
      'Height 8 · pill · track #E2E8F0 · saved fill Navy 700',
      'Pending segment: Gold 500 stripes (45°, 4dp) after the saved fill',
      'Always paired with a written % and amount (never the bar alone)',
      '% = saved × 100 ÷ target in whole numbers',
    ]),
    comp('App bar & stepper', `${appBar('Send money')}${stepper(2)}`, [
      'App bar min height 64 · back button 48×48, icon 24 · title 20/28 Bold Navy 900',
      'Stepper: label 12/16 SemiBold #475569 · 3 segments, height 4, gap 6',
      'Done segments Navy 700 · remaining #E2E8F0',
    ]),
    comp('Bottom navigation', bottomNav('Home'), [
      'Min height 72 · white · 1 top border #E2E8F0 · 3 equal items',
      'Icon 24 in a 56×32 pill indicator · active indicator Gold tint #FBF3D5',
      'Label 12/16 · active Bold Navy 900 · inactive Medium #64748B',
    ]),
    comp(
      'Bottom sheet',
      `<div style="display:flex;flex-direction:column;gap:12px;padding:12px 16px 16px;border-radius:24px 24px 0 0;background:#FFFFFF;"><div style="align-self:center;width:32px;height:4px;border-radius:999px;background:#CBD5E1;"></div><div style="font-size:20px;line-height:28px;font-weight:800;color:#0B1F3A;">Add to Rent 2027</div>${btn('primary', 'Add ₦5,000.00')}</div>`,
      ['Radius 24 (top corners) · padding 12 / 16 / 16 · gap 16', 'Handle 32×4 pill #CBD5E1', 'Title 20/28 ExtraBold Navy 900 · sits on the scrim'],
      'rgba(11,31,58,0.56)',
    ),
    comp('Notes & hints', `${note('shield', 'This transfer can only go through once.')}${note('clock', 'Saved on your phone until you reconnect.', { bg: '#FEF3C7', fg: '#B45309' })}${inlineHint('info', 'Tier 1 accounts can send up to ₦50,000.00 per transfer.')}`, [
      'Note: radius 12 · padding 12 / 16 · icon 20 + gap 12 · body 14/20 #0F172A',
      'Info note on Navy tint #E8EDF5 · pending note on #FEF3C7',
      'Inline hint: icon 16 + gap 8 · 12/16 #475569, no background',
    ]),
  ].join('')}</div>`;

  return doc(
    `<div style="display:flex;flex-direction:column;gap:48px;width:1280px;padding:48px;background:#F5F7FA;">
<div style="display:flex;flex-direction:column;gap:8px;"><div style="font-size:40px;line-height:48px;font-weight:800;color:#0B1F3A;letter-spacing:-0.5px;">NovaPay design spec</div><div style="font-size:16px;line-height:24px;color:#475569;">Android frame 360×800dp · 8dp grid · Plus Jakarta Sans (bundled with the app, no download) · all text at least 4.5:1 contrast. Sizes are dp; text sizes are sp and follow the system font setting.</div></div>
${section('Colour', 'Every colour used in the screens. Two-tone swatches show text colour / background.', colours)}
${section('Type scale', 'Amounts always use tabular figures so digits line up in lists.', type)}
${section('Spacing, radius & elevation', '', `<div style="display:grid;grid-template-columns:repeat(3, minmax(0, 1fr));gap:16px;align-items:start;">${spacing}${radii}${elevation}</div>`)}
${section('Components', 'Each sample is drawn with the same values used on the screens.', components)}
</div>`,
  );
}

// ---------- Annotated home ----------

function homeAnnotated() {
  SCALE = 1;
  const boxes = [
    [1, 304, 20, 40, 40, 999],
    [2, 16, 72, 328, 216, 20],
    [3, 36, 220, 138, 48, 12],
    [4, 16, 304, 328, 66, 16],
    [5, 292, 386, 52, 48, 8],
    [6, 16, 450, 328, 65, 16],
    [7, 32, 739, 56, 32, 999],
    [8, 0, 728, 360, 72, 0],
  ];
  const marker = (n, extra = '') =>
    `<div style="flex-shrink:0;display:flex;align-items:center;justify-content:center;width:24px;height:24px;border-radius:999px;background:#E11D48;color:#FFFFFF;font-size:12px;line-height:16px;font-weight:800;${extra}">${n}</div>`;
  const overlay = boxes
    .map(
      ([n, x, y, w, h, r]) =>
        `<div style="position:absolute;left:${x}px;top:${y}px;width:${w}px;height:${h}px;border:1.5px dashed #E11D48;border-radius:${r}px;"></div>${marker(
          n,
          `position:absolute;left:${Math.max(x - 10, -10)}px;top:${y - 10}px;box-shadow:0 0 0 2px #FFFFFF;`,
        )}`,
    )
    .join('');
  const entry = (n, title, lines) =>
    `<div style="display:flex;gap:12px;">${marker(n)}<div style="display:flex;flex-direction:column;gap:4px;"><div style="font-size:14px;line-height:20px;font-weight:700;color:#0B1F3A;">${title}</div>${lines
      .map((l) => `<div style="font-size:13px;line-height:18px;color:#334155;">${l}</div>`)
      .join('')}</div></div>`;
  const left = [
    entry(1, 'Greeting & avatar', ['Padding 16 / 16 / 8', '"Good evening," 14/20 Regular #475569', 'Name 20/28 Bold Navy 900', 'Avatar 40 circle · Navy 700 · initials 14/20 Bold white']),
    entry(2, 'Balance card', ['Radius 20 · padding 20 · gap 16 · fill Navy 900 #0B1F3A', 'Label 14/20 Medium #A9B8CF', 'Amount 32/40 ExtraBold white, tabular · kobo part 20/28', 'Caption 12/16 #A9B8CF', 'Eye button: 48×48 touch area, icon 20']),
    entry(3, 'Card actions', ['Min height 48 · radius 12 · gap 12 between · icon 20 + gap 8', 'Send: fill Gold 500 #C9A227 · label 14/20 Bold Navy 900', 'Save: 1.5 border #A9B8CF · label 14/20 SemiBold white']),
    entry(4, 'NovaSave tile', ['Radius 16 · padding 12 / 16 · 1 border #E2E8F0', 'Icon well 40 · Gold tint #FBF3D5 · icon #8A6D0F', 'Title 14/20 SemiBold · meta 12/16 #475569', 'Chevron 20 #64748B']),
  ].join('');
  const right = [
    entry(5, 'Section header', ['Min height 48 · title 16/24 Bold Navy 900', '"See all" 14/20 SemiBold Navy 700, 48 touch height']),
    entry(6, 'Transaction tile', ['Min height 64 · padding 12 / 16 · gap 12', 'Avatar 40 · title 14/20 SemiBold · meta 12/16', 'Amount 14/20 Bold tabular · incoming in #15803D with +', 'List: radius 16 · divider 1 #EEF2F6 inset 68']),
    entry(7, 'Active nav indicator', ['56×32 pill · Gold tint #FBF3D5', 'Icon 24 Navy 900 · label 12/16 Bold']),
    entry(8, 'Bottom navigation', ['Min height 72 · white · 1 top border #E2E8F0', '3 equal items · inactive icon + label #64748B Medium']),
    entry('S', 'Screen', ['Frame 360×800 · background #F5F7FA', 'Side padding 16 · vertical gap 16 between blocks', 'Transactions list is lazy (ListView.builder)']),
  ].join('');
  const col = (inner) => `<div style="flex-shrink:0;display:flex;flex-direction:column;gap:28px;width:280px;padding-top:12px;">${inner}</div>`;
  return doc(
    `<div style="display:flex;flex-direction:column;gap:24px;width:1080px;padding:40px;background:#FFFFFF;">
<div style="display:flex;flex-direction:column;gap:4px;"><div style="font-size:28px;line-height:36px;font-weight:800;color:#0B1F3A;">Home — annotated</div><div style="font-size:14px;line-height:20px;color:#475569;">Numbers match the dashed boxes. Sizes in dp, text sizes in sp.</div></div>
<div style="display:flex;gap:40px;align-items:flex-start;">${col(left)}<div style="position:relative;flex-shrink:0;width:360px;height:800px;border-radius:4px;box-shadow:0 0 0 1px #E2E8F0;">${homeScreen()}${overlay}</div>${col(right)}</div>
</div>`,
    '#FFFFFF',
  );
}

// ---------- Write artboards ----------

const screens = [
  ['Main', () => homeScreen(), '1 · Home — online'],
  ['HomeOffline', () => homeScreen({ offline: true }), '2 · Home — offline, pending & failed'],
  ['HomeLargeText', () => homeScreen(), '3 · Home — 200% text', 2],
  ['SendRecipient', () => sendRecipient(), '4 · Send — recipient'],
  ['SendAmount', () => sendAmount(), '5 · Send — amount'],
  ['SendConfirm', () => sendConfirm(), '6 · Send — confirm'],
  ['SendSent', () => sendSent(), '7 · Send — sent'],
  ['SendQueued', () => sendQueued(), '8 · Send — queued offline'],
  ['SaveGoals', () => saveGoals(), '9 · NovaSave — goals'],
  ['SaveCreate', () => saveCreate(), '10 · NovaSave — create goal'],
  ['SaveContribute', () => saveContribute(), '11 · NovaSave — contribute'],
  ['SaveGoalPending', () => saveGoalPending(), '12 · NovaSave — pending contribution'],
  ['ErrorAccount', () => sendRecipient({ error: true }), '13 · Error — invalid account number'],
  ['ErrorAmount', () => sendAmount({ error: true }), '14 · Error — amount over balance'],
  ['SyncFailed', () => syncFailed(), '15 · Failed sync — details'],
  ['SendAmountLargeText', () => sendAmount(), '16 · Send amount — 200% text', 2],
];

const rows = [
  ['Main', 'HomeOffline', 'HomeLargeText'],
  ['SendRecipient', 'SendAmount', 'SendConfirm', 'SendSent', 'SendQueued'],
  ['SaveGoals', 'SaveCreate', 'SaveContribute', 'SaveGoalPending'],
  ['ErrorAccount', 'ErrorAmount', 'SyncFailed', 'SendAmountLargeText'],
];
const rowNotes = [
  'Wallet home (F1, F4)\nThe balance comes from a whole-kobo integer. Offline: banner on top, available = balance − pending, and Pending / Failed chips with icon + word.',
  'Send Money (F2, F4)\nRecipient → Amount → Confirm. The reference on Confirm comes from the idempotency key made once per attempt. Sent and Queued are the two possible outcomes.',
  'NovaSave (F3, F4)\nProgress % uses whole-number maths (saved × 100 ÷ target). Pending contributions are drawn separately and not counted as saved.',
  'Errors & accessibility (C3)\nInline errors disable Continue. Failed syncs are never retried automatically. The 200% text screens show content reflowing instead of clipping.',
];

const artboards = [];
const files = [];
for (const [name, build, title, scale = 1] of screens) {
  SCALE = scale;
  const file = `${name}.dc.html`;
  writeFileSync(join(OUT, file), doc(build()));
  files.push(file);
  const r = rows.findIndex((row) => row.includes(name));
  const c = rows[r].indexOf(name);
  artboards.push({ file, title, x: c * 440, y: r * 1000, w: 360, h: 800, page: 'page-1' });
}
writeFileSync(join(OUT, 'HomeAnnotated.dc.html'), homeAnnotated());
writeFileSync(join(OUT, 'Specs.dc.html'), specs());
files.push('HomeAnnotated.dc.html', 'Specs.dc.html');
artboards.push({ file: 'HomeAnnotated.dc.html', title: 'Home — annotated redlines', x: 0, y: 0, w: 1080, h: 980, page: 'page-2' });
artboards.push({ file: 'Specs.dc.html', title: 'Design spec — colour, type, components', x: 1160, y: 0, w: 1280, h: 3600, page: 'page-2' });

const canvas = {
  pages: [
    { id: 'page-1', name: 'Screens' },
    { id: 'page-2', name: 'Spec sheet & redlines' },
  ],
  artboards,
  annotations: [
    ...rowNotes.map((text, i) => ({ id: `row-${i + 1}`, x: -380, y: i * 1000, w: 320, text, page: 'page-1' })),
    { id: 'spec-source', x: 0, y: -170, w: 520, text: 'These values are the source of truth for the Flutter theme (lib/core/theme/app_theme.dart).', page: 'page-2' },
  ],
  launch: { view: 'canvas', page: 'page-1' },
};
writeFileSync(join(OUT, 'canvas.json'), JSON.stringify(canvas, null, 2));
console.log(`Wrote ${files.length} artboards + canvas.json to ${OUT}`);
console.log(files.map((f) => `--artboard ${f}`).join(' '));
