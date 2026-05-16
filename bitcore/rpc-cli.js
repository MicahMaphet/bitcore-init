#!/usr/bin/env node

import os from "os";
import fs from "fs";
import { createRequire } from "module";
const require = createRequire(import.meta.url);
const { CryptoRpc } = require(`${os.homedir()}/dev/bitcore/packages/crypto-rpc`);

const args = process.argv.slice(2);

const pathIndex = args.indexOf('--path');
let path;
if (pathIndex !== -1) {
  path = args[pathIndex + 1];
  args.splice(pathIndex, 2);
} else {
  path = process.env.BITCORE_CONFIG_PATH;
}

const chain = args[0].toUpperCase();
const network = args[1];
const command = args[2];
if (!(chain && network && command)) {
  console.log(`Please specify chain, network, and command. Got: chain: ${chain} network: ${network} command: ${command}`);
  process.exit(1);
}
args.splice(0, 3);
const rpcArgs = {};
for (let i = 0; i < args.length; i++) {
  if (!args[i].startsWith('--'))
    continue;
  rpcArgs[args[i].slice(2)] = args[i + 1];
  args.splice(i, 2);
  i--;
}

const config = JSON.parse(fs.readFileSync(path)).bitcoreNode;
const chainConfig = config.chains[chain];
if (!chainConfig) {
  console.log(`Chain ${chain} is not in config ${path}, try:\n${Object.keys(config.chains)}`)
  process.exit(1);
}

if (!chainConfig[network]) {
  console.log(`Chain ${chain} does not have config for network ${network}`);
  process.exit(1);
}

const networkConfig = chainConfig[network];
const rpcConfig = networkConfig.rpc || networkConfig.providers[0];

const rpc = new CryptoRpc({
  chain,
  protocol: rpcConfig.protocol || 'http',
  host: rpcConfig.host,
  port: rpcConfig.port,
  user: rpcConfig.username,
  pass: rpcConfig.password
}).get(chain);

console.log(await rpc[command](rpcArgs));
