import { task } from 'hardhat/config'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

import { createGetHreByEid } from '@layerzerolabs/devtools-evm-hardhat'
import { ChainType, endpointIdToChainType, endpointIdToNetwork } from '@layerzerolabs/lz-definitions'
import { getDeploymentAddressAndAbi } from '@layerzerolabs/lz-evm-sdk-v2'

import layerzeroConfig from '../../layerzero.config'
import { DebugLogger, KnownErrors } from '../common/utils'

task(
    'lz:oft:evm:import-openzeppelin-network',
    'Import the open zeppelin network.json file based on the current contract impl'
).setAction(async (_, hre: HardhatRuntimeEnvironment) => {
    const { contracts } = typeof layerzeroConfig === 'function' ? await layerzeroConfig() : layerzeroConfig
    const getHreByEid = createGetHreByEid(hre)

    for (const {
        contract: { eid, contractName, address },
    } of contracts) {
        if (endpointIdToChainType(eid) !== ChainType.EVM) {
            continue
        }

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

        const { address: lzEndpointAddr } = getDeploymentAddressAndAbi(endpointIdToNetwork(eid), 'EndpointV2')
        const proxyAddress = contractName ? (await eidHre.deployments.get(contractName)).address : address!
        const alloOFT = await eidHre.ethers.getContractFactory('AlloOFTUpgradeable')

        await eidHre.upgrades.forceImport(proxyAddress, alloOFT, { constructorArgs: [lzEndpointAddr] })
    }
})
