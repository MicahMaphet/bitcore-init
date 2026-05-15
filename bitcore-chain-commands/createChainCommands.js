#!/usr/bin/env node

import fs from 'fs';

const args = process.argv.slice(2);

const pathIndex = args.indexOf('--path');
let path;
if (pathIndex !== -1) {
  path = args[pathIndex + 1];
  args.splice(pathIndex, 2);
  console.log(`Using config at ${path}`);
} else {
  path = process.env.BITCORE_CONFIG_PATH;
  console.log(`Using config from environmental variable ${path}`);
}

const config = JSON.parse(fs.readFileSync(path));

let commands = '';
const chains = config.bitcoreNode.chains;
for (const chain in chains) {
  const chainConfig = chains[chain];
  switch (chain) {
    case 'BTC':
      const rpc = chainConfig.regtest.rpc;
      commands += `alias btc='bitcoin-cli -rpcport=${rpc.port} -rpcpassword=${rpc.password} -rpcuser=${rpc.username}'\n`;
      commands += `alias btc-mine='btc generatetoaddress 1 $address'\n`;
      break;
    case 'ETH':
      const ethProvider = chainConfig.regtest.providers[0];
      commands += `alias eth='geth-linux-amd64-1.17.3-117e067f/geth attach ${ethProvider.protocol}://${ethProvider.host}:${ethProvider.port}'\n`;
      break;
    default:
      console.log(`${chain} not supported`);
      break;
  }
}
console.log('='.repeat(80));
console.log(commands);