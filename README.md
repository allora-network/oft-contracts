# oft-contracts

This repository contains sources of OFT contracts related to the **\$ALLO** token, and reference its deployments on different networks.

## Deployments

### Details

The native **\$ALLO** comes from the Allora Cosmos SDK based blockchain, in order to make it available to LayerZero ecosystem it is bridged with the Sei network over IBC (i.e. a Cosmos SDK based chain with EVM capabilities). From Sei a token pointer contract makes the native **\$ALLO** token available through an ERC-20 on EVM side, the `AlloOFTAdapter` contract is then used using this pointer as inner token to make it available to the LZ ecosystem. The other networks have the `AlloOFT` contract deployed.

When sending tokens from Sei side, as the OFT adapter manages an ERC-20 2 transactions are needed, a first one to approche the adapter to spend tokens from the ERC-20 and then the lz send.

### Testnets

### Sei devnet

Token pointer contract: [`0xc7e7A1B625225fEd006B3DdF6f402e45664D266a`](https://seitrace.com/address/0xc7e7A1B625225fEd006B3DdF6f402e45664D266a?chain=arctic-1)

OFT adapter contract: [`0x7A8e661524daf2c41AC1df0bAa91f42098Ad6eA9`](https://seitrace.com/address/0x7A8e661524daf2c41AC1df0bAa91f42098Ad6eA9?chain=arctic-1)

### Sepolia testnet

OFT contract: [`0xa9C316683dfBE81Be03C408340B5ab92295A8203`](https://sepolia.etherscan.io/address/0xa9c316683dfbe81be03c408340b5ab92295a8203)

Token view: https://sepolia.etherscan.io/token/0xa9c316683dfbe81be03c408340b5ab92295a8203

## Developing Contracts

### Installing dependencies

```bash
pnpm install
```

### Compiling your contracts

This project supports both `hardhat` and `forge` compilation:

```bash
pnpm compile
```

If you prefer one over the other, you can use the tooling-specific commands:

```bash
pnpm compile:forge
pnpm compile:hardhat
```

### Running tests

Similarly to the contract compilation, we support both `hardhat` and `forge` tests. By default, the `test` command will execute both:

```bash
pnpm test
```

If you prefer one over the other, you can use the tooling-specific commands:

```bash
pnpm test:forge
pnpm test:hardhat
```

## Deploying Contracts

Set up deployer wallet/account:

- Rename `.env.example` -> `.env`
- Choose your preferred means of setting up your deployer wallet/account:

```
MNEMONIC="test test test test test test test test test test test junk"
or...
PRIVATE_KEY="0xabc...def"
```

- Fund this address with the corresponding chain's native tokens you want to deploy to.

To deploy your contracts to your desired blockchains, run the following command in your project's folder:

```bash
npx hardhat lz:deploy
```

More information about available CLI arguments can be found using the `--help` flag:

```bash
npx hardhat lz:deploy --help
```

Finally, to wire the contracts and create the paths:

```bash
npx hardhat lz:oapp:wire --oapp-config testnet.layerzero.config.ts
```

## Sending tokens

The `lz:oft:send` hardhat task is available to send tokens through the LayerZero bridge, find below some examples:

```bash
# Send 1$ALLO from Base Sepolia devnet to Ethereum Sepolia testnet, in that way there's 2 transactions, a first approval on the token pointer contract and then the send.
npx hardhat lz:oft:send --amount 1000000 --to-network sepolia-testnet --network base-sepolia-testnet

# Send 1$ALLO from Base Sepolia to another wallet on Etheruem Sepolia testnet
npx hardhat lz:oft:send --amount 1000000 --to-network sepolia-testnet --network base-sepolia-testnet --to 0xCbe7f0aee92040aA91A7259A0474d6276Fa81AD8

# Send 1$ALLO from Sepolia testnet to Base Sepolia
npx hardhat lz:oft:send --amount 1000000 --network sepolia-testnet --to-network base-sepolia-testnet
```
