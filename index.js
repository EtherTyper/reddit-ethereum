#!/usr/bin/env node
import fetch from "node-fetch";
import fs from "fs";
import path from "path";
import util from "util";
import yargs from "yargs";
import { hideBin } from "yargs/helpers";
const argv = yargs(hideBin(process.argv))
  .option("network", {
    type: "string",
  })
  .option("contract", {
    type: "string",
  })
  .option("apikey", {
    type: "string",
  }).argv;

const api_response = await (
    await fetch(
      `https://api-${argv.network}.etherscan.io/api?module=contract&action=getsourcecode&address=${argv.contract}&apikey=${argv.apikey}`
    )
  ).text();
await util.promisify(fs.writeFile)("./api.json", api_response);

const api_result = JSON.parse(api_response).result[0];
const compiler_version = api_result.CompilerVersion;
console.log(compiler_version);
const source_field = api_result.SourceCode.slice(1, -1);
await util.promisify(fs.writeFile)("./compiler_version.txt", compiler_version);
await util.promisify(fs.writeFile)("./source.json", source_field);

const sources = JSON.parse(source_field).sources;

for (const contract in sources) {
    await util.promisify(fs.mkdir)(path.dirname(contract), { recursive: true });
    await util.promisify(fs.writeFile)(contract, sources[contract].content);
    console.log(`Writing ${contract}.`);
}
