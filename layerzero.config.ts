import { EndpointId } from '@layerzerolabs/lz-definitions'
import { ExecutorOptionType } from '@layerzerolabs/lz-v2-utilities'
import { generateConnectionsConfig } from '@layerzerolabs/metadata-tools'

import { getOftStoreAddress } from './tasks/solana'

import type { OAppEnforcedOption, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

const baseSepoliaContract: OmniPointHardhat = {
    eid: EndpointId.BASESEP_V2_TESTNET,
    contractName: 'AlloOFTUpgradeable',
}

const sepoliaContract: OmniPointHardhat = {
    eid: EndpointId.SEPOLIA_V2_TESTNET,
    contractName: 'AlloOFTUpgradeable',
}

const solanaDevnetContract: OmniPointHardhat = {
    eid: EndpointId.SOLANA_V2_TESTNET,
    address: getOftStoreAddress(EndpointId.SOLANA_V2_TESTNET),
}

const EVM_ENFORCED_OPTIONS: OAppEnforcedOption[] = [
    {
        msgType: 1,
        optionType: ExecutorOptionType.LZ_RECEIVE,
        gas: 187000,
        value: 0,
    },
    {
        msgType: 2,
        optionType: ExecutorOptionType.LZ_RECEIVE,
        gas: 187000,
        value: 0,
    },
    {
        msgType: 2,
        optionType: ExecutorOptionType.COMPOSE,
        index: 0,
        gas: 340000,
        value: 0,
    },
]

const SOLANA_ENFORCED_OPTIONS: OAppEnforcedOption[] = [
    {
        msgType: 1,
        optionType: ExecutorOptionType.LZ_RECEIVE,
        gas: 200000,
        value: 2500000,
    },
    {
        msgType: 2,
        optionType: ExecutorOptionType.LZ_RECEIVE,
        gas: 200000,
        value: 2500000,
    },
    {
        msgType: 2,
        optionType: ExecutorOptionType.COMPOSE,
        index: 0,
        gas: 200000,
        value: 2500000,
    },
]

export default async function () {
    const connections = await generateConnectionsConfig([
        [
            sepoliaContract,
            baseSepoliaContract,
            [['LayerZero Labs'], []],
            [15, 15],
            [EVM_ENFORCED_OPTIONS, EVM_ENFORCED_OPTIONS],
        ],
        [
            sepoliaContract,
            solanaDevnetContract,
            [['LayerZero Labs'], []],
            [15, 32],
            [SOLANA_ENFORCED_OPTIONS, EVM_ENFORCED_OPTIONS],
        ],
        [
            baseSepoliaContract,
            solanaDevnetContract,
            [['LayerZero Labs'], []],
            [15, 32],
            [SOLANA_ENFORCED_OPTIONS, EVM_ENFORCED_OPTIONS],
        ],
    ])

    return {
        contracts: [
            {
                contract: baseSepoliaContract,
                config: {
                    delegate: '0x8330bcC0770bAb19Cd4AcEdb4DC4c0d9B3E9528E',
                    owner: '0x8330bcC0770bAb19Cd4AcEdb4DC4c0d9B3E9528E',
                },
            },
            {
                contract: sepoliaContract,
                config: {
                    delegate: '0x8330bcC0770bAb19Cd4AcEdb4DC4c0d9B3E9528E',
                    owner: '0x8330bcC0770bAb19Cd4AcEdb4DC4c0d9B3E9528E',
                },
            },
            {
                contract: solanaDevnetContract,
                config: {
                    delegate: 'DGWdm6qvYQMXyc7aiAJBWwPJoojbUGLCPGGn686DcAwh',
                    owner: 'DGWdm6qvYQMXyc7aiAJBWwPJoojbUGLCPGGn686DcAwh',
                },
            },
        ],
        connections,
    }
}
