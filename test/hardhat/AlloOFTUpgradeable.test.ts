import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from 'chai'
import { Contract, ContractFactory } from 'ethers'
import { deployments, ethers, upgrades } from 'hardhat'

describe('AlloOFT Test', () => {
    // Constant representing a mock Endpoint ID for testing purposes
    const eidA = 1
    const eidB = 2
    // Declaration of variables to be used in the test suite
    let AlloOFT: ContractFactory
    let EndpointV2Mock: ContractFactory
    let ownerA: SignerWithAddress
    let ownerB: SignerWithAddress
    let endpointOwner: SignerWithAddress
    let myOFTA: Contract
    let myOFTB: Contract
    let mockEndpointV2A: Contract
    let mockEndpointV2B: Contract

    before(async function () {
        AlloOFT = await ethers.getContractFactory('AlloOFTUpgradeable')

        // Fetching the first three signers (accounts) from Hardhat's local Ethereum network
        const signers = await ethers.getSigners()

        ;[ownerA, ownerB, endpointOwner] = signers

        // The EndpointV2Mock contract comes from @layerzerolabs/test-devtools-evm-hardhat package
        // and its artifacts are connected as external artifacts to this project
        //
        // Unfortunately, hardhat itself does not yet provide a way of connecting external artifacts,
        // so we rely on hardhat-deploy to create a ContractFactory for EndpointV2Mock
        //
        // See https://github.com/NomicFoundation/hardhat/issues/1040
        const EndpointV2MockArtifact = await deployments.getArtifact('EndpointV2Mock')
        EndpointV2Mock = new ContractFactory(EndpointV2MockArtifact.abi, EndpointV2MockArtifact.bytecode, endpointOwner)
    })

    // beforeEach hook for setup that runs before each test in the block
    beforeEach(async function () {
        // Deploying a mock LZEndpoint with the given Endpoint ID
        mockEndpointV2A = await EndpointV2Mock.deploy(eidA)
        mockEndpointV2B = await EndpointV2Mock.deploy(eidB)

        // Deploying two instances of MyOFT contract with different identifiers and linking them to the mock LZEndpoint
        myOFTA = await AlloOFT.deploy(mockEndpointV2A.address)
        myOFTB = await AlloOFT.deploy(mockEndpointV2B.address)

        // Setting destination endpoints in the LZEndpoint mock for each MyOFT instance
        await mockEndpointV2A.setDestLzEndpoint(myOFTB.address, mockEndpointV2B.address)
        await mockEndpointV2B.setDestLzEndpoint(myOFTA.address, mockEndpointV2A.address)
    })

    it('should upgrade', async () => {
        // Deploying the upgradeable contract
        const AlloOFTUpgradeable = await ethers.getContractFactory('AlloOFTUpgradeable')
        const alloOFTUpgradeable = await upgrades.deployProxy(
            AlloOFTUpgradeable,
            ['Allora', '$ALLO', ownerA.address, ethers.constants.AddressZero],
            {
                initializer: 'initialize',
                constructorArgs: [mockEndpointV2A.address],
                unsafeAllow: ['constructor', 'state-variable-immutable', 'missing-initializer-call'],
            }
        )
        const alloOFTUpgradeableImpl = (await upgrades.admin.getInstance(ownerA)).functions.getProxyImplementation(
            alloOFTUpgradeable.address
        )

        // Upgrade the contract to the mock, so it has a "mint" function
        const AlloOFTUpgradeableMock = await ethers.getContractFactory('AlloOFTUpgradeableMock')
        const alloOFTUpgradeableMock = await upgrades.upgradeProxy(alloOFTUpgradeable.address, AlloOFTUpgradeableMock, {
            constructorArgs: [mockEndpointV2A.address],
            unsafeAllow: ['constructor', 'state-variable-immutable', 'missing-initializer', 'missing-initializer-call'],
        })

        // Ensure the proxy remains constant after the upgrade
        expect(alloOFTUpgradeable.address).to.equal(alloOFTUpgradeableMock.address)
        const alloOFTUpgradeableMockImpl = (await upgrades.admin.getInstance(ownerA)).functions.getProxyImplementation(
            alloOFTUpgradeableMock.address
        )
        // ensure the implementation address changed
        expect(alloOFTUpgradeableImpl).to.not.equal(alloOFTUpgradeableMockImpl)
        const [intialBalance] = await alloOFTUpgradeableMock.functions.balanceOf(ownerA.address)
        // ensure we can mint now
        await (await alloOFTUpgradeableMock.functions.publicMint(ownerA.address, 100)).wait()
        const [finalBalance] = await alloOFTUpgradeableMock.functions.balanceOf(ownerA.address)
        expect(finalBalance.toNumber()).to.equal(intialBalance.add(100).toNumber())

        // Downgrade the contract to remove mint
        const alloOFTUpgradeableAgain = await upgrades.upgradeProxy(
            alloOFTUpgradeableMock.address,
            AlloOFTUpgradeable,
            {
                constructorArgs: [mockEndpointV2A.address],
                unsafeAllow: [
                    'constructor',
                    'state-variable-immutable',
                    'missing-initializer',
                    'missing-initializer-call',
                ],
            }
        )
        // Ensure the proxy remains constant after the upgrade
        expect(alloOFTUpgradeableMock.address).to.equal(alloOFTUpgradeableAgain.address)
        // Ensure that the tokens don't disappear into thin air
        const [postUpgradeBalance] = await alloOFTUpgradeableMock.functions.balanceOf(ownerA.address)
        expect(postUpgradeBalance.toNumber()).to.equal(finalBalance.toNumber())
    })
})
