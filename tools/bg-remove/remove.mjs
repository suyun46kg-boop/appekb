import { removeBackground } from "@imgly/background-removal-node";
import { readFile, writeFile, mkdir, copyFile } from "fs/promises";
import { join } from "path";

const root = "c:/Users/suyun/suyun1/project2/ekbkyrgyzdar";
const srcDir = join(root, "assets/images/categories");
const backupDir = join(root, "tools/bg-remove/backup");

const files = [
  "category_apartment.png",
  "category_job.png",
  "category_border.png",
  "category_auto.png",
  "category_ticket.png",
  "category_services.png",
  "category_sale_v2.png",
  "category_parttime.png",
];

await mkdir(backupDir, { recursive: true });

for (const name of files) {
  const inputPath = join(srcDir, name);
  const backupPath = join(backupDir, name);
  console.log(`Processing ${name}...`);
  await copyFile(inputPath, backupPath);

  const input = await readFile(inputPath);
  const blobIn = new Blob([input], { type: "image/png" });

  const blob = await removeBackground(blobIn, {
    debug: true,
    model: "medium",
    output: { format: "image/png", quality: 1 },
    progress: (key, current, total) => {
      if (total) {
        const pct = Math.round((current / total) * 100);
        process.stdout.write(`\r  ${key}: ${pct}%   `);
      }
    },
  });

  const buffer = Buffer.from(await blob.arrayBuffer());
  await writeFile(inputPath, buffer);
  console.log(`\n  done (${(buffer.length / 1024).toFixed(1)} KB)`);
}

console.log("All category icons now have transparent backgrounds.");
