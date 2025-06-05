import { EndpointId } from '@layerzerolabs/lz-definitions'

import { getOftStoreAddress } from './tasks/solana'

import type { OAppOmniGraphHardhat, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

const baseSepoliaContract: OmniPointHardhat = {
    eid: EndpointId.BASESEP_V2_TESTNET,
    contractName: 'AlloOFTUpgradeable',
}

const sepoliaContract: OmniPointHardhat = {
    eid: EndpointId.SEPOLIA_V2_TESTNET,
    contractName: 'AlloOFTUpgradeable',
}

const solanaContract: OmniPointHardhat = {
    eid: EndpointId.SOLANA_V2_TESTNET,
    address: getOftStoreAddress(EndpointId.SOLANA_V2_TESTNET),
}

// const SOLANA_ENFORCED_OPTIONS: OAppEnforcedOption[] = [
//     {
//         msgType: 1,
//         optionType: ExecutorOptionType.LZ_RECEIVE,
//         gas: 200000,
//         value: 2500000,
//     },
// ]

const config: OAppOmniGraphHardhat = {
    contracts: [
        {
            contract: baseSepoliaContract,
        },
        {
            contract: sepoliaContract,
        },
        {
            contract: solanaContract,
        },
    ],
    connections: [
        {
            from: baseSepoliaContract,
            to: sepoliaContract,
        },
        {
            from: sepoliaContract,
            to: baseSepoliaContract,
        },
        {
            from: sepoliaContract,
            to: solanaContract,
        },
        {
            from: solanaContract,
            to: sepoliaContract,
        },
    ],
}

export default config
