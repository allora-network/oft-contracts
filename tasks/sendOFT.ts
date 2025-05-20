import { BigNumberish, BytesLike } from 'ethers'
import { task } from 'hardhat/config'

import { types } from '@layerzerolabs/devtools-evm-hardhat'
import { EndpointId } from '@layerzerolabs/lz-definitions'
import { Options, addressToBytes32 } from '@layerzerolabs/lz-v2-utilities'

interface Args {
    to: string
    amount: string
    toNetwork: string
}

interface SendParam {
    dstEid: EndpointId
    to: BytesLike
    amountLD: BigNumberish
    minAmountLD: BigNumberish
    extraOptions: BytesLike
    composeMsg: BytesLike
    oftCmd: BytesLike
}

task('lz:oft:send', 'Send OFT tokens')
    .addOptionalParam(
        'to',
        'Address to transfer tokens to. Defaults to sender if not specified',
        undefined,
        types.string
    )
    .addParam('amount', 'Token amount transfer', undefined, types.string)
    .addParam('toNetwork', 'Network to transfer tokens to', undefined, types.string)
    .setAction(async (args: Args, hre) => {
        const [signer] = await hre.ethers.getSigners()
        let toAddress = signer.address
        if (args.to) {
            if (!hre.ethers.utils.isAddress(args.to)) {
                console.error(`Invalid address: ${args.to}`)
                return
            }
            toAddress = args.to
        }

        const dstEid = hre.config.networks[args.toNetwork]?.eid
        if (!dstEid) {
            console.error(`Invalid network: ${args.toNetwork}`)
            return
        }

        console.log(
            `Transfering '${args.amount}uallo' FROM address '${signer.address}' on network '${hre.network.name}' TO address '${toAddress}' on network '${args.toNetwork}' (EID: ${dstEid})`
        )

        const oftDeployment = await hre.deployments.get('AlloOFTUpgradeable')
        const oftContract = new hre.ethers.Contract(oftDeployment.address, oftDeployment.abi, signer)

        const sendParam: SendParam = {
            dstEid,
            to: addressToBytes32(toAddress),
            amountLD: args.amount,
            minAmountLD: args.amount,
            extraOptions: Options.newOptions().addExecutorLzReceiveOption(65000, 0).toBytes(),
            composeMsg: hre.ethers.utils.arrayify('0x'),
            oftCmd: hre.ethers.utils.arrayify('0x'),
        }

        const { nativeFee } = await oftContract.quoteSend(sendParam, false)
        const r = await oftContract.send(sendParam, [nativeFee, 0], signer.address, { value: nativeFee })
        console.log(`TX initiated: ${r.hash}`)
    })
