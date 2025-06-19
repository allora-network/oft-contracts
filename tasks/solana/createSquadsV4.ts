import { toWeb3JsKeypair } from '@metaplex-foundation/umi-web3js-adapters'
import { Keypair, PublicKey } from '@solana/web3.js'
import * as multisig from '@sqds/multisig'
import { task } from 'hardhat/config'

import { types as devtoolsTypes } from '@layerzerolabs/devtools-evm-hardhat'
import { EndpointId } from '@layerzerolabs/lz-definitions'

import { deriveConnection } from './index'

interface Args {
    eid: EndpointId
    members: string
    threshold: number
}

task('lz:oapp:solana:create-squads-v4', 'Create a squads v4 multisig')
    .addParam('eid', 'The endpoint ID for the Solana network', undefined, devtoolsTypes.eid)
    .addParam(
        'members',
        'A comma-separated list of public keys representing the members of the multisig',
        undefined,
        undefined
    )
    .addParam('threshold', "The multisig's threshold", 1, devtoolsTypes.int)
    .setAction(async ({ eid, members, threshold }: Args) => {
        const { Permission, Permissions } = multisig.types

        const createKey = Keypair.generate()
        // Derive the multisig account PDA
        const [multisigPda] = multisig.getMultisigPda({
            createKey: createKey.publicKey,
        })

        const { connection, umiWalletKeyPair } = await deriveConnection(eid)
        const creator = toWeb3JsKeypair(umiWalletKeyPair)

        const programConfigPda = multisig.getProgramConfigPda({})[0]
        const programConfig = await multisig.accounts.ProgramConfig.fromAccountAddress(connection, programConfigPda)
        const configTreasury = programConfig.treasury

        const sig = await multisig.rpc.multisigCreateV2({
            connection,
            createKey,
            creator,
            multisigPda,
            threshold: threshold,
            timeLock: 0,
            configAuthority: null,
            rentCollector: null,
            treasury: configTreasury,
            members: members.split(',').map((x: string) => {
                return { key: new PublicKey(x.trim()), permissions: Permissions.all() }
            }),
            sendOptions: { skipPreflight: true },
        })

        console.log(`Multisig created. Solscan link: https://solscan.io/tx/${sig}?cluster=devnet`)
    })
