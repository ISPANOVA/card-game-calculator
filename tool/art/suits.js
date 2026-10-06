// Suit shapes in a 100×100 box.
const SUITS = {
  heart: 'M50 90 C22 68 4 50 4 30 C4 14 16 4 30 4 C40 4 47 10 50 18 C53 10 60 4 70 4 C84 4 96 14 96 30 C96 50 78 68 50 90 Z',
  spade: 'M50 4 C78 30 96 44 96 60 C96 75 84 83 71 83 C63 83 56 79 53 73 C54 83 58 90 66 96 L34 96 C42 90 46 83 47 73 C44 79 37 83 29 83 C16 83 4 75 4 60 C4 44 22 30 50 4 Z',
  diamond: 'M50 2 L88 50 L50 98 L12 50 Z',
  club: 'M50 4 A20 20 0 0 1 66 36 A20 20 0 1 1 58 70 C59 82 62 90 68 96 L32 96 C38 90 41 82 42 70 A20 20 0 1 1 34 36 A20 20 0 0 1 50 4 Z',
};
function suit(name, x, y, size, fill) {
  const s = size / 100;
  return `<path d="${SUITS[name]}" fill="${fill}" transform="translate(${x - size / 2} ${y - size / 2}) scale(${s})"/>`;
}
function card(cx, cy, w, h, rot, name, color) {
  return `<g transform="rotate(${rot} ${cx} ${cy})">
    <rect x="${cx - w / 2 + 6}" y="${cy - h / 2 + 14}" width="${w}" height="${h}" rx="${w * 0.11}" fill="#000" opacity="0.28" filter="url(#blur)"/>
    <rect x="${cx - w / 2}" y="${cy - h / 2}" width="${w}" height="${h}" rx="${w * 0.11}" fill="url(#ivory)" stroke="#E2C275" stroke-width="${w * 0.018}"/>
    ${suit(name, cx, cy + h * 0.02, w * 0.56, color)}
    ${suit(name, cx - w * 0.33, cy - h * 0.36, w * 0.16, color)}
    ${suit(name, cx + w * 0.33, cy + h * 0.36, w * 0.16, color)}
  </g>`;
}
function badge(cx, cy, r) {
  const t = r * 0.16, l = r * 0.42;
  return `<circle cx="${cx}" cy="${cy + r * 0.08}" r="${r}" fill="#000" opacity="0.3" filter="url(#blur)"/>
  <circle cx="${cx}" cy="${cy}" r="${r}" fill="url(#gold)" stroke="#F7E7B5" stroke-width="${r * 0.05}"/>
  <rect x="${cx - l}" y="${cy - r * 0.32 - t / 2}" width="${2 * l}" height="${t}" rx="${t / 2}" fill="#0A3324"/>
  <rect x="${cx - t / 2}" y="${cy - r * 0.32 - l}" width="${t}" height="${2 * l}" rx="${t / 2}" fill="#0A3324" transform="scale(1 1)"/>
  <rect x="${cx - l}" y="${cy + r * 0.40 - t / 2}" width="${2 * l}" height="${t}" rx="${t / 2}" fill="#0A3324"/>`;
}
const DEFS = `<defs>
  <radialGradient id="felt" cx="50%" cy="40%" r="70%"><stop offset="0" stop-color="#1A7A55"/><stop offset="0.55" stop-color="#0C3D2B"/><stop offset="1" stop-color="#04211A"/></radialGradient>
  <linearGradient id="ivory" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFFDF5"/><stop offset="1" stop-color="#EFE4C6"/></linearGradient>
  <linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F7E3A6"/><stop offset="0.5" stop-color="#E2C275"/><stop offset="1" stop-color="#A9822F"/></linearGradient>
  <filter id="blur" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="14"/></filter>
</defs>`;
// The mark centred in a box of `size`, scaled by k (1 = fills the icon).
function mark(size, k) {
  const c = size / 2, u = size / 1024 * k;
  const w = 330 * u, h = 460 * u;
  return card(c - 95 * u, c - 10 * u, w, h, -14, 'heart', '#C62828') +
    card(c + 70 * u, c + 10 * u, w, h, 9, 'spade', '#16201B') +
    badge(c + 250 * u, c + 250 * u, 125 * u);
}
