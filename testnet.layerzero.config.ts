import { EndpointId } from '@layerzerolabs/lz-definitions'
import { ExecutorOptionType } from '@layerzerolabs/lz-v2-utilities'

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
            config: {
                enforcedOptions: [
                    {
                        msgType: 1,
                        optionType: ExecutorOptionType.LZ_RECEIVE,
                        gas: 60000,
                        value: 0,
                    },
                ],
            },
        },
        {
            from: arctic1Contract,
            to: sepoliaContract,
            config: {
                enforcedOptions: [
                    {
                        msgType: 1,
                        optionType: ExecutorOptionType.LZ_RECEIVE,
                        gas: 60000,
                        value: 0,
                    },
                ],
            },
        },
    ],
}

export default config
