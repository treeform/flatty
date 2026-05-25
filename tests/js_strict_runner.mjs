import { readFileSync } from "node:fs";
import vm from "node:vm";

const file = process.argv[2];

if (file === undefined) {
  throw new Error("Usage: node tests/js_strict_runner.mjs <compiled-js-file>");
}

vm.runInThisContext(`"use strict";\n${readFileSync(file, "utf8")}`, {
  filename: file,
});
