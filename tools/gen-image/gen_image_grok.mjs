#!/usr/bin/env node
// Генерация / редактирование изображений через xAI Grok Imagine.
// Без зависимостей (Node 18+). Ключ берётся из переменной XAI_API_KEY.
//
// Генерация:
//   node tools/gen-image/gen_image_grok.mjs "описание" [--aspect 1:1] [--n 1] [--out out/name.png]
// Редактирование (исходная картинка):
//   node tools/gen-image/gen_image_grok.mjs "что изменить" --image in.png [--out out/edited.png]

import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { dirname, extname, join } from 'node:path';

const MODEL = process.env.XAI_IMAGE_MODEL || 'grok-imagine-image';
const API = 'https://api.x.ai/v1/images';

function parseArgs(argv) {
  const opts = { aspect: '1:1', n: 1 };
  const rest = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const next = () => argv[++i];
    if (a === '--image') opts.image = next();
    else if (a === '--aspect') opts.aspect = next();
    else if (a === '--n') opts.n = Number(next());
    else if (a === '--out') opts.out = next();
    else if (a === '--model') opts.model = next();
    else rest.push(a);
  }
  opts.prompt = rest.join(' ').trim();
  return opts;
}

const MIME = { '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp' };

async function dataUri(path) {
  const type = MIME[extname(path).toLowerCase()] || 'image/png';
  return `data:${type};base64,${(await readFile(path)).toString('base64')}`;
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  const key = process.env.XAI_API_KEY;
  if (!key) throw new Error('XAI_API_KEY не задан');
  if (!opts.prompt) throw new Error('Нужно описание (prompt)');

  const body = {
    model: opts.model || MODEL,
    prompt: opts.prompt,
    n: opts.n,
    response_format: 'b64_json',
  };
  let endpoint = 'generations';
  if (opts.image) {
    endpoint = 'edits';
    body.image = { url: await dataUri(opts.image), type: 'image_url' };
  } else {
    body.aspect_ratio = opts.aspect;
  }

  const res = await fetch(`${API}/${endpoint}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const json = await res.json();
  if (!res.ok) throw new Error(`${res.status}: ${JSON.stringify(json.error ?? json)}`);

  const out = opts.out || join('tools', 'gen-image', 'out', `grok_${Date.now()}.png`);
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
}

main().catch((e) => {
  console.error('Ошибка:', e.message);
  process.exit(1);
});
