#!/usr/bin/env node
// One-time migration: extract every base64 data: URI from the legacy
// index.html / merch.html, dedupe byte-identical placeholders by content
// hash, and write each unique image to /public/images/<section>/<name>.
//
// Slugs below were assigned by hand from the documented context of each
// occurrence (data-slot values, nearest heading/id, alt text, or CSS var
// name) found during the pre-rebuild exploration of the legacy files, not
// derived at runtime — see the main site plan for that analysis. The
// script still verifies by hash that any two occurrences sharing a slug
// really are byte-identical, and fails loudly if that assumption breaks.
//
// Usage: node scripts/migrate-images.mjs
// Idempotent: safe to re-run; re-writes the same bytes to the same paths.

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { createHash } from "node:crypto";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = join(__dirname, "..");
const IMAGES_ROOT = join(REPO_ROOT, "public", "images");

// Legacy source files and the slug assigned to each base64 occurrence,
// in document order. Extension is derived from the actual matched MIME
// type at runtime, not hardcoded here.
const SOURCES = [
  {
    file: "index.html",
    slugs: [
      "texture/tex",
      "texture/tex-soft",
      "nav/bookmark",
      "hero/collage-1",
      "hero/collage-2",
      "hero/collage-3",
      "social/photo",
      "about/photo",
      "how/room",
      "books/current-cover",
      "books/shelf-placeholder",
      "books/shelf-placeholder",
      "books/shelf-placeholder",
      "books/shelf-placeholder",
      "books/shelf-placeholder",
      "champions/trophy",
      "community/post-placeholder",
      "community/post-placeholder",
      "community/post-placeholder",
      "community/avatar-placeholder",
      "community/avatar-placeholder",
      "community/avatar-placeholder",
      "gallery/photo-big",
      "gallery/photo-2",
      "gallery/photo-3",
      "gallery/photo-4",
      "gallery/photo-5",
      "join/photo",
      "footer/mark",
    ],
  },
  {
    file: "merch.html",
    slugs: ["texture/tex", "texture/tex-soft", "nav/bookmark"],
  },
];

const MIME_EXT = { png: "png", jpeg: "jpg", jpg: "jpg", webp: "webp" };
const DATA_URI_RE = /data:image\/(png|jpe?g|webp);base64,([A-Za-z0-9+/=]+)/g;

function lineOf(text, index) {
  return text.slice(0, index).split("\n").length;
}

function main() {
  /** @type {Map<string, {ext: string, hash: string, path: string}>} */
  const writtenBySlug = new Map();
  /** @type {Map<string, string>} first slug that wrote a given hash, for the dedupe log */
  const slugByHash = new Map();
  const log = [];
  let totalOccurrences = 0;

  for (const { file, slugs } of SOURCES) {
    const filePath = join(REPO_ROOT, file);
    const text = readFileSync(filePath, "utf8");
    const matches = [...text.matchAll(DATA_URI_RE)];

    if (matches.length !== slugs.length) {
      throw new Error(
        `${file}: found ${matches.length} base64 data URIs but ${slugs.length} slugs are mapped. ` +
          `The legacy file changed since the slug table was written — update SOURCES before re-running.`
      );
    }

    matches.forEach((match, i) => {
      totalOccurrences += 1;
      const [, mime, base64] = match;
      const ext = MIME_EXT[mime];
      const slug = slugs[i];
      const buffer = Buffer.from(base64, "base64");
      const hash = createHash("sha256").update(buffer).digest("hex");
      const outPath = join(IMAGES_ROOT, `${slug}.${ext}`);

      const existingForSlug = writtenBySlug.get(slug);
      if (existingForSlug && existingForSlug.hash !== hash) {
        throw new Error(
          `Slug "${slug}" was assigned to two different images (hash mismatch) — ` +
            `${file}:${lineOf(text, match.index)}. Fix the slug table, don't silently overwrite.`
        );
      }

      mkdirSync(dirname(outPath), { recursive: true });
      writeFileSync(outPath, buffer);
      writtenBySlug.set(slug, { ext, hash, path: outPath });

      const dedupedFrom = slugByHash.get(hash);
      slugByHash.set(hash, slug);

      log.push({
        file,
        line: lineOf(text, match.index),
        mime,
        bytes: buffer.length,
        hash: hash.slice(0, 12),
        slug,
        outPath: outPath.replace(REPO_ROOT + "/", ""),
        dedupedFrom: dedupedFrom && dedupedFrom !== slug ? dedupedFrom : undefined,
      });
    });
  }

  const uniqueFiles = writtenBySlug.size;
  const uniqueHashes = new Set([...writtenBySlug.values()].map((v) => v.hash)).size;

  if (uniqueFiles !== uniqueHashes) {
    throw new Error(
      `Self-check failed: ${uniqueFiles} unique output paths but ${uniqueHashes} unique content hashes. ` +
        `Two different slugs wrote the same content (fine) or the same slug got two extensions (not fine) — inspect the log.`
    );
  }

  const logPath = join(__dirname, "migrate-images.log.json");
  writeFileSync(logPath, JSON.stringify(log, null, 2));

  console.log(`Processed ${totalOccurrences} base64 occurrences across ${SOURCES.length} files.`);
  console.log(`Wrote ${uniqueFiles} unique image files to ${IMAGES_ROOT.replace(REPO_ROOT + "/", "")}/`);
  console.log(`Mapping log: ${logPath.replace(REPO_ROOT + "/", "")}`);
  console.log(`Self-check: unique output paths (${uniqueFiles}) == unique content hashes (${uniqueHashes}) ✓`);
}

main();
