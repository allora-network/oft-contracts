import { EndpointId } from '@layerzerolabs/lz-definitions'

import type { OAppOmniGraphHardhat, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

const baseSepoliaContract: OmniPointHardhat = {
    eid: EndpointId.BASESEP_V2_TESTNET,
    contractName: 'AlloOFTUpgradeable',
}

const sepoliaContract: OmniPointHardhat = {
    eid: EndpointId.SEPOLIA_V2_TESTNET,
    contractName: 'AlloOFTUpgradeable',
}

const config: OAppOmniGraphHardhat = {
    contracts: [
        {
            contract: baseSepoliaContract,
        },
        {
            contract: sepoliaContract,
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
    ],
}

export default config
