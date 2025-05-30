# ALLO OFT Contracts

This repository contains the smart contract implementation for the **ALLO** ERC20, which is designed to be both OFT (Omnichain Fungible Token) compliant and compatible with the Eureka bridging solution for cross-chain interoperability between EVM and Cosmos chains.

## Overview

The `AlloOFTUpgradeable` contract is an upgradeable implementation that combines:

- OFT compliance for cross-chain token transfers
- Eureka bridging compatibility through the `IMintableAndBurnable` interface
- Upgradeable architecture for future improvements

The token has 18 decimals on EVM chains and uses 6 shared decimals for cross-chain operations and implements specific security measures for supply management through the ICS20 proxy contract.

## Key Features

- **Cross-Chain Compatibility**: Supports both LayerZero's OFT standard and Eureka's bridging solution
- **Upgradeable**: Built with upgradeability in mind for future improvements
- **Supply Management**: Controlled minting and burning through authorized ICS20 proxy
- **Security**: Strict access controls for supply modifications
- **Standard Compliance**: Implements both `OFT` and `IMintableAndBurnable` interfaces

## Key Functions

- `initialize`: Sets up the token with name, symbol, delegate, and ICS20 proxy
- `mint`: Creates new tokens (restricted to ICS20 proxy)
- `burn`: Destroys tokens (restricted to ICS20 proxy)
- `setICS20Proxy`: Updates the ICS20 proxy address (owner only)

## Security Considerations

- Supply modifications (mint/burn) are restricted to the ICS20 proxy contract
- The contract is upgradeable, allowing for future improvements
- Strict access controls for administrative functions
- Implementation of standard interfaces for interoperability

## Setup

1. Install dependencies
```
pnpm install
forge install
```

2. Setup your environment
```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your configuration
# Required variables:
# - MNEMONIC or PRIVATE_KEY for deployment
# - RPC URLs for the networks you want to deploy to
```

## Development

### Compilation

```bash
# Compile both Hardhat and Foundry contracts
pnpm compile

# Compile only Hardhat contracts
pnpm compile:hardhat

# Compile only Foundry contracts
pnpm compile:forge
```

### Testing

```bash
# Run all tests
pnpm test

# Run only Hardhat tests
pnpm test:hardhat

# Run only Foundry tests
pnpm test:forge
```

### Linting

```bash
# Run all linters
pnpm lint

# Fix linting issues
pnpm lint:fix
```

## Deployments

### Testnets

- Base Sepolia
  OFT contract: [`0xff5ba7b0b2de8b1bc9fb2e67142461442b40c820`](https://sepolia.basescan.org/address/0xff5ba7b0b2de8b1bc9fb2e67142461442b40c820)

- Ethreum Sepolia
  OFT contract: [`0x6cb5249164657905a2d9d4fdf3f928c0d2238c34`](https://sepolia.etherscan.io/address/0x6cb5249164657905a2d9d4fdf3f928c0d2238c34)

Token view: https://sepolia.etherscan.io/address/0x6cb5249164657905a2d9d4fdf3f928c0d2238c34

### Testing transfers between EVM chains

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
