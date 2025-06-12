import { type DeployFunction } from 'hardhat-deploy/types'

import { EndpointId, endpointIdToNetwork } from '@layerzerolabs/lz-definitions'
import { getDeploymentAddressAndAbi } from '@layerzerolabs/lz-evm-sdk-v2'

const contractName = 'AlloOFTUpgradeable'
// Ethereum mainnet ICS20 proxy address (https://docs.skip.build/go/eureka/custom-erc20-integration#access-control-requirements)
const ICS20_PROXY_ADDRESS = '0xa348CfE719B63151F228e3C30EB424BA5a983012'

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
                    args: ['Allora', 'ALLO', signer.address, ICS20_PROXY_ADDRESS],
                },
            },
        },
    })
}

deploy.tags = [contractName]

export default deploy
