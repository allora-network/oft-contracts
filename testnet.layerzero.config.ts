import { EndpointId } from '@layerzerolabs/lz-definitions'

import type { OAppOmniGraphHardhat, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

const sepoliaContract: OmniPointHardhat = {
    eid: EndpointId.SEPOLIA_V2_TESTNET,
    contractName: 'AlloOFT',
}

const arctic1Contract: OmniPointHardhat = {
    eid: EndpointId.SEI_V2_TESTNET,
    contractName: 'AlloOFTAdapter',
}

const config: OAppOmniGraphHardhat = {
    contracts: [
        {
            contract: sepoliaContract,
        },
        {
            contract: arctic1Contract,
        },
    ],
    connections: [
        {
            from: sepoliaContract,
            to: arctic1Contract,
        },
        {
            from: arctic1Contract,
            to: sepoliaContract,
        },
    ],
}

export default config
