# ALLO OFT Contracts

This repository contains the smart contract implementation for the **ALLO** ERC20, which is designed to be both OFT (
Omnichain Fungible Token) compliant and compatible with the Eureka bridging solution for cross-chain interoperability
between EVM and Cosmos chains.

## Overview

### EVM contract

The `AlloOFTUpgradeable` contract is an upgradeable implementation that combines:

- OFT compliance for cross-chain token transfers
- Eureka bridging compatibility through the `IMintableAndBurnable` interface
- Upgradeable architecture for future improvements

The token has 18 decimals on EVM chains and uses 6 shared decimals for cross-chain operations and implements specific
security measures for supply management through the ICS20 proxy contract.

### SVM contract

The Solana OFT contract is designed to be compatible with the LayerZero OFT standard but not the Eureka bridging
solution as it is not supported at the moment.

The token is upgradeable, allowing for future enhancements. Its decimals (i.e. local and shared) are configurable when
creating the contracts and defaults to 6 shared and 9 locals.

## EVM

### Key Features

- **Cross-Chain Compatibility**: Supports both LayerZero's OFT standard and Eureka's bridging solution
- **Upgradeable**: Built with upgradeability in mind for future improvements
- **Supply Management**: Controlled minting and burning through authorized ICS20 proxy
- **Security**: Strict access controls for supply modifications
- **Standard Compliance**: Implements both `OFT` and `IMintableAndBurnable` interfaces

### Key Functions

- `initialize`: Sets up the token with name, symbol, delegate, and ICS20 proxy
- `mint`: Creates new tokens (restricted to ICS20 proxy)
- `burn`: Destroys tokens (restricted to ICS20 proxy)
- `setICS20Proxy`: Updates the ICS20 proxy address (owner only)

### Security Considerations

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

### Linting

```bash
# Run all linters
pnpm lint

# Fix linting issues
pnpm lint:fix
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

### Compilation

#### EVM

```bash
# Compile both Hardhat and Foundry contracts
pnpm compile

# Compile only Hardhat contracts
pnpm compile:hardhat

# Compile only Foundry contracts
pnpm compile:forge
```

#### SVM

Create `programId` keypair files by running:

```bash
solana-keygen new -o target/deploy/endpoint-keypair.json --force
solana-keygen new -o target/deploy/oft-keypair.json --force

anchor keys sync
```

:warning: `--force` flag overwrites the existing keys with the ones you generate.

Run

```
anchor keys list
```

to view the generated programIds (public keys). The output should look something like this:

```
endpoint: <ENDPOINT_PROGRAM_ID>
oft: <OFT_PROGRAM_ID>
```

Build the program:

```bash
anchor build -v -e OFT_ID=<OFT_PROGRAM_ID>
```

## Deployments

### Testnets

- Base Sepolia
  OFT contract: [
  `0xff5ba7b0b2de8b1bc9fb2e67142461442b40c820`](https://sepolia.basescan.org/address/0xff5ba7b0b2de8b1bc9fb2e67142461442b40c820)

- Ethreum Sepolia
  OFT contract: [
  `0x6cb5249164657905a2d9d4fdf3f928c0d2238c34`](https://sepolia.etherscan.io/address/0x6cb5249164657905a2d9d4fdf3f928c0d2238c34)

Token view: https://sepolia.etherscan.io/address/0x6cb5249164657905a2d9d4fdf3f928c0d2238c34

### Testing transfers between EVM chains

Similarly to the contract compilation, we support both `hardhat` and `forge` tests. By default, the `test` command will
execute both:

```bash
pnpm test
```

If you prefer one over the other, you can use the tooling-specific commands:

```bash
pnpm test:forge
pnpm test:hardhat
```

## Deploying Contracts

### EVM

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

### SVM

#### Preview Rent Costs for the Solana OFT

:information_source: The majority of the SOL required to deploy your program will be for [**rent
**](https://solana.com/docs/core/fees#rent) (specifically, for the minimum balance of SOL required
for [rent-exemption](https://solana.com/docs/core/fees#rent-exempt)), which is calculated based on the amount of bytes
the program or account uses. Programs typically require more rent than PDAs as more bytes are required to store the
program's executable code.

In our case, the OFT Program's rent accounts for roughly 99% of the SOL needed during deployment, while the other
accounts' rent, OFT Store, Mint, Mint Authority Multisig and Escrow make up for only a fraction of the SOL needed.

You can preview how much SOL would be needed for the program account. Note that the total SOL required would to be
slightly higher than just this, to account for the other accounts that need to be created.

```bash
solana rent $(wc -c < target/verifiable/oft.so)
```

You should see an output such as

```bash
Rent-exempt minimum: 3.87415872 SOL
```

:information_source: LayerZero's default deployment path for Solana OFTs require you to deploy your own OFT program as
this means you own the Upgrade Authority and don't rely on LayerZero to manage that authority for you.
Read [this](https://neodyme.io/en/blog/solana_upgrade_authority/) to understand more no why this is important.

#### Deploy the Solana OFT

While for building, we must use Solana `v1.17.31`, for deploying, we will be using `v1.18.26` as it provides an improved
program deployment experience (i.e. ability to attach priority fees and also exact-sized on-chain program length which
prevents needing to provide 2x the rent as in `v1.17.31`).

##### Temporarily switch to Solana `v1.18.26`

First, we switch to Solana `v1.18.26` (remember to switch back to `v1.17.31` later)

```bash
sh -c "$(curl -sSfL https://release.anza.xyz/v1.18.26/install)"
```

##### (Recommended) Deploying with a priority fee

The `deploy` command will run with a priority fee. Read the section on ['Deploying Solana programs with a priority fee
'](https://docs.layerzero.network/v2/developers/solana/technical-reference/solana-guidance#deploying-solana-programs-with-a-priority-fee)
to learn more.

##### Run the deploy command

```bash
solana program deploy --program-id target/deploy/oft-keypair.json target/verifiable/oft.so -u devnet --with-compute-unit-price <COMPUTE_UNIT_PRICE_IN_MICRO_LAMPORTS>
```

:information_source: the `-u` flag specifies the RPC URL that should be used. The options are
`mainnet-beta, devnet, testnet, localhost`, which also have their respective shorthands: `-um, -ud, -ut, -ul`

:warning: If the deployment is slow, it could be that the network is congested and you might need to increase the
priority fee.

##### Switch back to Solana `1.17.31`

:warning: After deploying, make sure to switch back to v1.17.31 after deploying. If you need to rebuild artifacts, you
must use Solana CLI version `1.17.31` and Anchor version `0.29.0`

```bash
sh -c "$(curl -sSfL https://release.anza.xyz/v1.17.31/install)"
```

#### Create the Solana OFT

```bash
pnpm hardhat lz:oft:solana:create --eid 40168 --program-id <PROGRAM_ID> --name Allora --symbol ALLO --additional-minters ""
```

The `--additional-minters ""` option is important to be able to update the additional minters later on, we may need this
to make it compatible with IBC Eureka.

#### Initialize the OFT Program's SendConfig and ReceiveConfig Accounts

:warning: Do this only when initializing the OFT for the first time. The only exception is if a new pathway is added
later. If so, run this again to properly initialize the pathway.

Run the following command to init the pathway config. This step is unique to pathways that involve Solana.

```bash
npx hardhat lz:oft:solana:init-config --oapp-config layerzero.config.ts
```

## Wire Contracts

To wire the contracts and create the paths:

```bash
npx hardhat lz:oapp:wire --oapp-config layerzero.config.ts
```

## Sending tokens

The `lz:oft:send` hardhat task is available to send tokens through the LayerZero bridge, find below some examples:

```bash
# Send 1 ALLO from Ethereum Sepolia to Base Sepolia
npx hardhat lz:oft:send --src-eid 40161 --dst-eid 40245 --amount 1 --to 0xF2489e0d20Df54514B371dF0360316B244a275c6

# Send 1 ALLO from Ethereum Sepolia to Solana
npx hardhat lz:oft:send --src-eid 40161 --dst-eid 40168 --amount 1 --to 97zzVFruAgRyAsd9Rj491e5BZ8L8m3AY3R5tg3x6gchX

# Send 1 ALLO from Solana to Ethereum Sepolia
npx hardhat lz:oft:send --src-eid 40168 --dst-eid 40161 --amount 1 --to 0xF2489e0d20Df54514B371dF0360316B244a275c6
```
