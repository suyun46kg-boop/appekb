#!/usr/bin/env node
// Генерация / редактирование изображений через OpenAI gpt-image-2.
// Без зависимостей (Node 18+). Ключ берётся из переменной OPENAI_API_KEY.
//
// Генерация:
//   node tools/gen-image/gen_image.mjs "описание" [--size 1024x1024] [--quality high|medium|low] [--n 1] [--out out/name.png]
// Редактирование (одна или несколько исходных картинок, опционально маска):
//   node tools/gen-image/gen_image.mjs "что изменить" --image in.png [--image ref2.png] [--mask mask.png] [--out out/edited.png]

import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { basename, dirname, extname, join } from 'node:path';

const MODEL = process.env.OPENAI_IMAGE_MODEL || 'gpt-image-2';
const API = 'https://api.openai.com/v1/images';

function parseArgs(argv) {
  const opts = { images: [], size: '1024x1024', quality: 'high', n: 1 };
  const rest = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const next = () => argv[++i];
    if (a === '--image') opts.images.push(next());
    else if (a === '--mask') opts.mask = next();
    else if (a === '--size') opts.size = next();
    else if (a === '--quality') opts.quality = next();
    else if (a === '--n') opts.n = Number(next());
    else if (a === '--out') opts.out = next();
    else rest.push(a);
  }
  opts.prompt = rest.join(' ').trim();
  return opts;
}

const MIME = { '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp' };

async function fileBlob(path) {
  const type = MIME[extname(path).toLowerCase()] || 'image/png';
  return new Blob([await readFile(path)], { type });
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  const key = process.env.OPENAI_API_KEY;
  if (!key) throw new Error('OPENAI_API_KEY не задан');
  if (!opts.prompt) throw new Error('Нужно описание (prompt)');

  let res;
  if (opts.images.length) {
    const form = new FormData();
    form.append('model', MODEL);
    form.append('prompt', opts.prompt);
    form.append('size', opts.size);
    form.append('quality', opts.quality);
    form.append('n', String(opts.n));
    for (const p of opts.images) form.append('image[]', await fileBlob(p), basename(p));
    if (opts.mask) form.append('mask', await fileBlob(opts.mask), basename(opts.mask));
    res = await fetch(`${API}/edits`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${key}` },
      body: form,
    });
  } else {
    res = await fetch(`${API}/generations`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: MODEL, prompt: opts.prompt, size: opts.size, quality: opts.quality, n: opts.n }),
    });
  }

  const json = await res.json();
  if (!res.ok) throw new Error(`${res.status}: ${JSON.stringify(json.error ?? json)}`);

  const out = opts.out || join('tools', 'gen-image', 'out', `img_${Date.now()}.png`);
  await mkdir(dirname(out), { recursive: true });
  const saved = [];
  for (const [i, item] of json.data.entries()) {
    const path = json.data.length > 1 ? out.replace(/(\.\w+)?$/, `_${i + 1}$1`) : out;
    const buf = item.b64_json
      ? Buffer.from(item.b64_json, 'base64')
      : Buffer.from(await (await fetch(item.url)).arrayBuffer());
    await writeFile(path, buf);
    saved.push(path);
  }
  console.log(saved.join('\n'));
  if (json.usage) console.error('usage:', JSON.stringify(json.usage));
}

main().catch((e) => {
  console.error('Ошибка:', e.message);
  process.exit(1);
});
