import { task, types } from 'hardhat/config'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

import { createGetHreByEid } from '@layerzerolabs/devtools-evm-hardhat'
import { ChainType, EndpointId, endpointIdToChainType, endpointIdToNetwork } from '@layerzerolabs/lz-definitions'
import { getDeploymentAddressAndAbi } from '@layerzerolabs/lz-evm-sdk-v2'

import layerzeroConfig from '../../layerzero.config'
import { DebugLogger, KnownErrors } from '../common/utils'

interface Args {
    eid: EndpointId
    newContractName: string
    safe: boolean
}

task('lz:oft:evm:upgrade', 'Upgrades an OFT contract on EVM network')
    .addParam('eid', 'Endpoint ID of the network to upgrade', undefined, types.int)
    .addParam('newContractName', 'The name of the contract to upgrade to', undefined, types.string)
    .addFlag(
        'safe',
        'If specified: only deploy the implementation, the proxy will need to be upgraded through the gnosis safe'
    )
    .setAction(async ({ eid, newContractName, safe }: Args, hre: HardhatRuntimeEnvironment) => {
        if (endpointIdToChainType(eid) !== ChainType.EVM) {
            throw new Error(`non-EVM eid (${eid}) not supported here`)
        }

        const getHreByEid = createGetHreByEid(hre)
        let eidHre: HardhatRuntimeEnvironment
        try {
            eidHre = await getHreByEid(eid)
        } catch (error) {
            DebugLogger.printErrorAndFixSuggestion(
                KnownErrors.ERROR_GETTING_HRE,
                `For network: ${endpointIdToNetwork(eid)}`
            )
            throw error
        }

        const { contracts } = typeof layerzeroConfig === 'function' ? await layerzeroConfig() : layerzeroConfig
        const proxy = contracts.find((c) => c.contract.eid === eid)

        if (!proxy) throw new Error(`No config for EID ${eid}`)
        const proxyAddress = proxy.contract.contractName
            ? (await eidHre.deployments.get(proxy.contract.contractName)).address
            : proxy.contract.address!

        const newOFT = await eidHre.ethers.getContractFactory(newContractName)

        const { address: lzEndpointAddr } = getDeploymentAddressAndAbi(endpointIdToNetwork(eid), 'EndpointV2')

        if (safe) {
            const resp = await eidHre.upgrades.prepareUpgrade(proxyAddress, newOFT, {
                kind: 'transparent',
                constructorArgs: [lzEndpointAddr],
                unsafeAllow: ['constructor', 'state-variable-immutable', 'missing-initializer-call'],
            })

            console.log(`Prepared upgrade for ${newContractName} at ${proxyAddress}. New contract addr: ${resp}`)
        } else {
            const resp = await eidHre.upgrades.upgradeProxy(proxyAddress, newOFT)
            console.log(`Proxy upgraded for ${newContractName} at ${proxyAddress}. New contract addr: ${resp}`)
        }
    })
