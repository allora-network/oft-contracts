import { EndpointId } from '@layerzerolabs/lz-definitions'

import type { OAppOmniGraphHardhat, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

const sepoliaContract: OmniPointHardhat = {
    eid: EndpointId.SEPOLIA_V2_TESTNET,
    contractName: 'AlloOFT',
}

const atlantic2Contract: OmniPointHardhat = {
    eid: EndpointId.SEI_V2_TESTNET,
    contractName: 'AlloOFTAdapter',
}

const config: OAppOmniGraphHardhat = {
    contracts: [
        {
            contract: sepoliaContract,
        },
        {
            contract: atlantic2Contract,
        },
    ],
    connections: [
        {
            from: sepoliaContract,
            to: atlantic2Contract,
        },
        {
            from: atlantic2Contract,
            to: sepoliaContract,
        },
    ],
}

export default config
