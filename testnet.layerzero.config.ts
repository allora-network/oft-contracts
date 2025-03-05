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
                sendLibrary: '0xcc1ae8Cf5D3904Cef3360A9532B477529b177cCE',
                receiveLibraryConfig: {
                    receiveLibrary: '0xdAf00F5eE2158dD58E0d3857851c432E34A3A851',
                    gracePeriod: BigInt(0),
                },
                sendConfig: {
                    executorConfig: {
                        executor: '0x718B92b5CB0a5552039B593faF724D182A881eDA',
                        maxMessageSize: 10000,
                    },
                    ulnConfig: {
                        confirmations: BigInt(2),
                        requiredDVNs: ['0x8eebf8b423B73bFCa51a1Db4B7354AA0bFCA9193'],
                        optionalDVNs: [],
                        optionalDVNThreshold: 0,
                    },
                },
                receiveConfig: {
                    ulnConfig: {
                        confirmations: BigInt(1),
                        requiredDVNs: ['0x8eebf8b423B73bFCa51a1Db4B7354AA0bFCA9193'],
                        optionalDVNs: [],
                        optionalDVNThreshold: 0,
                    },
                },
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
                sendLibrary: '0xd682ECF100f6F4284138AA925348633B0611Ae21',
                receiveLibraryConfig: {
                    receiveLibrary: '0xcF1B0F4106B0324F96fEfcC31bA9498caa80701C',
                    gracePeriod: BigInt(0),
                },
                sendConfig: {
                    executorConfig: {
                        executor: '0x55c175DD5b039331dB251424538169D8495C18d1',
                        maxMessageSize: 10000,
                    },
                    ulnConfig: {
                        confirmations: BigInt(1),
                        requiredDVNs: ['0xF49d162484290EAeAd7bb8C2c7E3a6f8f52e32d6'],
                        optionalDVNs: [],
                        optionalDVNThreshold: 0,
                    },
                },
                receiveConfig: {
                    ulnConfig: {
                        confirmations: BigInt(2),
                        requiredDVNs: ['0xF49d162484290EAeAd7bb8C2c7E3a6f8f52e32d6'],
                        optionalDVNs: [],
                        optionalDVNThreshold: 0,
                    },
                },
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
