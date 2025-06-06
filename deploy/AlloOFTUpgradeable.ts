import { type DeployFunction } from 'hardhat-deploy/types'

import { EndpointId, endpointIdToNetwork } from '@layerzerolabs/lz-definitions'
import { getDeploymentAddressAndAbi } from '@layerzerolabs/lz-evm-sdk-v2'

const contractName = 'AlloOFTUpgradeable'
// @note: since the $ALLO token doesn't have any initial supply,
// we can use a custom testing address for the ICS20 proxy for minting new tokens when testing
const ICS20_PROXY_ADDRESS = '0x0000000000000000000000000000000000000000'

const deploy: DeployFunction = async (hre) => {
    const { deploy } = hre.deployments
    const signer = (await hre.ethers.getSigners())[0]
    console.log(
        `Deploying ${contractName}
        Network: ${hre.network.name}
        Signer: ${signer.address}
        ICS20 Proxy: ${ICS20_PROXY_ADDRESS}`
    )

    const eid = hre.network.config.eid as EndpointId
    const lzNetworkName = endpointIdToNetwork(eid)

    const { address } = getDeploymentAddressAndAbi(lzNetworkName, 'EndpointV2')

    await deploy(contractName, {
        from: signer.address,
        args: [address],
        log: true,
        waitConfirmations: 10,
        skipIfAlreadyDeployed: false,
        proxy: {
            proxyContract: 'OpenZeppelinTransparentProxy',
            owner: signer.address,
            execute: {
                init: {
                    methodName: 'initialize',
                    args: ['Allora', '$ALLO', signer.address, ICS20_PROXY_ADDRESS],
                },
            },
        },
    })
}

deploy.tags = [contractName]

export default deploy
