// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { OFTTest } from "@layerzerolabs/oft-evm-upgradeable/test/OFT.t.sol";
import { EndpointV2Mock } from "@layerzerolabs/test-devtools-evm-foundry/contracts/mocks/EndpointV2Mock.sol";
import { AlloOFTUpgradeable } from "../../contracts/AlloOFTUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { IMintableAndBurnable } from "@cosmos/solidity-ibc-eureka/contracts/interfaces/IMintableAndBurnable.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import { IOFT, SendParam, OFTReceipt } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import { MessagingFee, MessagingReceipt } from "@layerzerolabs/oft-evm-upgradeable/contracts/oft/OFTCoreUpgradeable.sol";
import { OFTComposerMock } from "@layerzerolabs/oft-evm/test/mocks/OFTComposerMock.sol";
import { OFTComposeMsgCodec } from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";

contract MockICS20TransferProxy {
    IMintableAndBurnable public mintableBurnableToken;

    // @dev This is a mock function for showcasing triggering the burn function on the AlloOFTUpgradeable contract
    function bridgeTokensFromEvmToCosmos(address _from, uint256 _amount) public {
        mintableBurnableToken.burn(_from, _amount);
    }

    // @dev This is a mock function for showcasing triggering the mint function on the AlloOFTUpgradeable contract
    function bridgeTokensFromCosmosToEvm(address _to, uint256 _amount) public {
        mintableBurnableToken.mint(_to, _amount);
    }

    function setMintableBurnableToken(address _mintableBurnableToken) public {
        mintableBurnableToken = IMintableAndBurnable(_mintableBurnableToken);
    }
}

contract MockICS20TransferProxy2 is MockICS20TransferProxy {}

contract AlloOFTTestUpgrade is AlloOFTUpgradeable {
    bool public wasUpgradeFunctionCalled = false;

    constructor(address _endpoint) AlloOFTUpgradeable(_endpoint) {}

    function upgradeWorked() public pure returns (bool) {
        return true;
    }

    function upgradeFunction() public {
        wasUpgradeFunctionCalled = true;
    }
}

contract AlloOFTUpgradeableTest is OFTTest {
    using OptionsBuilder for bytes;

    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    AlloOFTUpgradeable alloErc20;
    AlloOFTUpgradeable alloErc20OftB;
    MockICS20TransferProxy ics20TransferProxy;

    address delegate = makeAddr("delegate");
    address proxyAdminContractAddress;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event ICS20ProxyUpdated(address indexed oldICS20Proxy, address indexed newICS20Proxy);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Errors
    error ERC20InvalidReceiver(address receiver);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidSpender(address spender);
    error OwnableUnauthorizedAccount(address msgSender);
    error UnauthorizedSupplyAdmin();
    error ERC20InsufficientBalance(address token, uint256 balance, uint256 amount);
    error ERC20InsufficientAllowance(address token, uint256 allowance, uint256 amount);

    function setUp() public override {
        super.setUp();

        // Deploy the AlloOFTUpgradeable contract and the ICS20TransferProxy contract
        ics20TransferProxy = new MockICS20TransferProxy();
        alloErc20 = AlloOFTUpgradeable(
            // @note: the proxy admin is a ProxyAdmin contract that is deployed in the OFTTest contract
            // the proxy admin owner is set in the proxyAdmin variable
            _deployContractAndProxy(
                type(AlloOFTUpgradeable).creationCode,
                abi.encode(address(endpoints[aEid])),
                abi.encodeWithSelector(
                    AlloOFTUpgradeable.initialize.selector,
                    "Allora",
                    "$ALLO",
                    delegate,
                    address(ics20TransferProxy)
                )
            )
        );
        alloErc20OftB = AlloOFTUpgradeable(
            _deployContractAndProxy(
                type(AlloOFTUpgradeable).creationCode,
                abi.encode(address(endpoints[bEid])),
                abi.encodeWithSelector(AlloOFTUpgradeable.initialize.selector, "Allora", "$ALLO", delegate, address(0))
            )
        );

        // config and wire the ofts
        address[] memory ofts = new address[](2);
        ofts[0] = address(alloErc20);
        ofts[1] = address(alloErc20OftB);

        vm.prank(delegate);
        alloErc20.setPeer(bEid, addressToBytes32(address(alloErc20OftB)));
        vm.prank(delegate);
        alloErc20OftB.setPeer(aEid, addressToBytes32(address(alloErc20)));

        // Set the mintableBurnableToken address in the ICS20TransferProxy contract
        ics20TransferProxy.setMintableBurnableToken(address(alloErc20));

        // Load Allora OFT proxy admin address
        bytes32 adminRaw = vm.load(address(alloErc20), ADMIN_SLOT);
        proxyAdminContractAddress = address(uint160(uint256(adminRaw)));
    }

    // ================================
    // Implementation tests
    // ================================

    function test_alloErc20DeploymentInitialization() public view {
        AlloOFTUpgradeable alloErc20Upgradeable = AlloOFTUpgradeable(address(alloErc20));
        assertEq(address(alloErc20Upgradeable.owner()), delegate);
        assertEq(address(alloErc20Upgradeable.ics20Proxy()), address(ics20TransferProxy));
        // ERC20 details
        assertEq(alloErc20Upgradeable.name(), "Allora");
        assertEq(alloErc20Upgradeable.symbol(), "$ALLO");
        assertEq(alloErc20Upgradeable.decimals(), 18);
        assertEq(alloErc20Upgradeable.totalSupply(), 0);
        // OFT details
        assertEq(alloErc20Upgradeable.sharedDecimals(), 6);
        assertEq(address(alloErc20Upgradeable.endpoint()), address(endpoints[aEid]));
    }

    // ICS20TransferProxy acccess rights tests
    function test_ICS20TransferProxyCanMint() public {
        assertEq(alloErc20.balanceOf(address(this)), 0);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), address(this), 100);
        ics20TransferProxy.bridgeTokensFromCosmosToEvm(address(this), 100);
        assertEq(alloErc20.balanceOf(address(this)), 100);
    }

    function test_ICS20TransferProxyCanBurn() public {
        // Mint 100 tokens since the intiail supply is 0
        ics20TransferProxy.bridgeTokensFromCosmosToEvm(address(this), 100);
        assertEq(alloErc20.balanceOf(address(this)), 100);

        // Burn 100 tokens
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(0), 100);
        ics20TransferProxy.bridgeTokensFromEvmToCosmos(address(this), 100);
        assertEq(alloErc20.balanceOf(address(this)), 0);
    }

    function test_EOAMintFails() public {
        vm.expectRevert(AlloOFTUpgradeable.UnauthorizedSupplyAdmin.selector);
        AlloOFTUpgradeable(address(alloErc20)).mint(address(this), 100);
    }

    function test_EOABurnFails() public {
        // Mint 100 tokens
        ics20TransferProxy.bridgeTokensFromCosmosToEvm(address(this), 100);
        assertEq(alloErc20.balanceOf(address(this)), 100);

        vm.expectRevert(AlloOFTUpgradeable.UnauthorizedSupplyAdmin.selector);
        AlloOFTUpgradeable(address(alloErc20)).burn(address(this), 100);
    }

    function test_ICS20TransferProxyCannotMintToZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(ERC20InvalidReceiver.selector, address(0)));
        ics20TransferProxy.bridgeTokensFromCosmosToEvm(address(0), 100);
    }

    function test_ICS20TransferProxyCannotBurnFromZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(ERC20InvalidSender.selector, address(0)));
        ics20TransferProxy.bridgeTokensFromEvmToCosmos(address(0), 100);
    }

    function test_onlyICS20TransferProxyCanMintAndBurn() public {
        MockICS20TransferProxy2 nonOwnerICS20TransferProxy = new MockICS20TransferProxy2();
        nonOwnerICS20TransferProxy.setMintableBurnableToken(address(alloErc20));

        vm.expectRevert(UnauthorizedSupplyAdmin.selector);
        nonOwnerICS20TransferProxy.bridgeTokensFromCosmosToEvm(address(this), 100);
        vm.expectRevert(UnauthorizedSupplyAdmin.selector);
        nonOwnerICS20TransferProxy.bridgeTokensFromEvmToCosmos(address(this), 100);
    }

    // Delegate acccess rights tests
    function test_ownerCanChangeICS20Proxy() public {
        // The contract owner is the delegate address
        address contractOwner = delegate;
        MockICS20TransferProxy2 newICS20TransferProxy = new MockICS20TransferProxy2();

        vm.startPrank(contractOwner);
        vm.expectEmit(true, true, true, true);
        emit ICS20ProxyUpdated(address(ics20TransferProxy), address(newICS20TransferProxy));
        AlloOFTUpgradeable(address(alloErc20)).setICS20Proxy(address(newICS20TransferProxy));
        vm.stopPrank();
        assertEq(AlloOFTUpgradeable(address(alloErc20)).ics20Proxy(), address(newICS20TransferProxy));
    }

    function test_nonOwnerCannotChangeICS20Proxy() public {
        MockICS20TransferProxy2 newICS20TransferProxy = new MockICS20TransferProxy2();
        address nonOwner = makeAddr("nonOwner");
        vm.startPrank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, nonOwner));
        AlloOFTUpgradeable(address(alloErc20)).setICS20Proxy(address(newICS20TransferProxy));
    }

    // Standard ERC20 tests

    // Transfer method tests
    function test_transfer() public {
        address sender = makeAddr("sender");
        // Mint tokens to this contract
        ics20TransferProxy.bridgeTokensFromCosmosToEvm(sender, 100);

        // Transfer to another address
        vm.startPrank(sender);
        address recipient = makeAddr("recipient");
        vm.expectEmit(true, true, true, true);
        emit Transfer(sender, recipient, 50);
        alloErc20.transfer(recipient, 50);
        vm.stopPrank();

        assertEq(alloErc20.balanceOf(recipient), 50);
        assertEq(alloErc20.balanceOf(sender), 50);
    }

    function test_transferFailsWithInsufficientBalance() public {
        // Mint only 50 tokens
        ics20TransferProxy.bridgeTokensFromCosmosToEvm(address(this), 50);

        // Try to transfer more than balance
        address recipient = makeAddr("recipient");
        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientBalance.selector, address(this), 50, 100));
        alloErc20.transfer(recipient, 100);
    }

    function test_transferFailsToZeroAddress() public {
        // Mint tokens to this contract
        ics20TransferProxy.bridgeTokensFromCosmosToEvm(address(this), 100);
        assertEq(alloErc20.balanceOf(address(this)), 100);

        vm.expectRevert(abi.encodeWithSelector(ERC20InvalidReceiver.selector, address(0)));
        alloErc20.transfer(address(0), 50);
    }

    function test_transferFrom() public {
        // Mint tokens to this contract
        ics20TransferProxy.bridgeTokensFromCosmosToEvm(address(this), 100);

        // Approve spender
        address spender = makeAddr("spender");
        address recipient = makeAddr("recipient");
        alloErc20.approve(spender, 50);

        // Transfer from
        vm.startPrank(spender);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), recipient, 50);
        alloErc20.transferFrom(address(this), recipient, 50);
        vm.stopPrank();

        assertEq(alloErc20.balanceOf(recipient), 50);
        assertEq(alloErc20.balanceOf(address(this)), 50);
        assertEq(alloErc20.allowance(address(this), spender), 0);
    }

    function test_transferFromFailsWithInsufficientAllowance() public {
        // Mint tokens to this contract
        ics20TransferProxy.bridgeTokensFromCosmosToEvm(address(this), 100);

        // Approve spender with insufficient allowance
        address spender = makeAddr("spender");
        address recipient = makeAddr("recipient");
        alloErc20.approve(spender, 25);

        // Try to transfer more than allowance
        vm.startPrank(spender);
        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, address(spender), 25, 50));
        alloErc20.transferFrom(address(this), recipient, 50);
        vm.stopPrank();
    }

    function test_transferFromFailsWithInsufficientBalance() public {
        // Mint tokens to this contract
        ics20TransferProxy.bridgeTokensFromCosmosToEvm(address(this), 25);

        // Approve spender
        address spender = makeAddr("spender");
        address recipient = makeAddr("recipient");
        alloErc20.approve(spender, 50);

        // Try to transfer more than balance
        vm.startPrank(spender);
        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientBalance.selector, address(this), 25, 50));
        alloErc20.transferFrom(address(this), recipient, 50);
        vm.stopPrank();
    }

    // Approve method tests
    function test_approve() public {
        address spender = makeAddr("spender");
        vm.expectEmit(true, true, false, true);
        emit Approval(address(this), spender, 100);
        alloErc20.approve(spender, 100);
        assertEq(alloErc20.allowance(address(this), spender), 100);
    }

    function test_approveZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(ERC20InvalidSpender.selector, address(0)));
        alloErc20.approve(address(0), 100);
    }

    // ================================
    // Deployment related tests
    // ================================

    function test_oftImplementationInitializationDisabled() public {
        bytes32 implementationRaw = vm.load(address(alloErc20), IMPLEMENTATION_SLOT);
        address implementationAddress = address(uint160(uint256(implementationRaw)));

        AlloOFTUpgradeable oftUpgradeableImplementation = AlloOFTUpgradeable(implementationAddress);

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        oftUpgradeableImplementation.initialize("Allora", "$ALLO", address(this), address(0));

        EndpointV2Mock endpoint = EndpointV2Mock(address(alloErc20.endpoint()));
        assertEq(endpoint.delegates(address(alloErc20)), delegate);
        assertEq(endpoint.delegates(implementationAddress), address(0));
    }

    function test_cannotInitializeTwice() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        alloErc20.initialize("Allora", "$ALLO", delegate, address(ics20TransferProxy));
    }

    function test_proxyAdminOwnership() public {
        ProxyAdmin proxyAdminContract = ProxyAdmin(proxyAdminContractAddress);
        assertEq(proxyAdminContract.owner(), proxyAdmin);

        address newOwner = makeAddr("newOwner");

        // Non-owner cannot transfer ownership
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(this)));
        proxyAdminContract.transferOwnership(newOwner);

        // Owner can transfer ownership
        vm.startPrank(proxyAdmin);
        proxyAdminContract.transferOwnership(newOwner);
        vm.stopPrank();

        assertEq(proxyAdminContract.owner(), newOwner);
    }

    // Test upgrade functionality
    function test_upgradeIsSuccessful() public {
        ProxyAdmin proxyAdminContract = ProxyAdmin(proxyAdminContractAddress);

        // Get the current implementation address
        bytes32 implementationRaw = vm.load(address(alloErc20), IMPLEMENTATION_SLOT);
        address initialImplementationAddress = address(uint160(uint256(implementationRaw)));

        // Deploy new implementation
        AlloOFTTestUpgrade newImplementation = new AlloOFTTestUpgrade(address(endpoints[aEid]));

        // Cast the proxy to ITransparentUpgradeableProxy
        ITransparentUpgradeableProxy transparentUpgradeableProxy = ITransparentUpgradeableProxy(address(alloErc20));

        // Non-owner cannot upgrade
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(this)));
        proxyAdminContract.upgradeAndCall(
            transparentUpgradeableProxy,
            address(newImplementation),
            "" // no initialization call
        );

        // Owner can upgrade
        vm.startPrank(proxyAdmin);
        proxyAdminContract.upgradeAndCall(
            transparentUpgradeableProxy,
            address(newImplementation),
            "" // no initialization call
        );
        vm.stopPrank();

        // Verify new implementation is set
        bytes32 currentImplementationRaw = vm.load(address(alloErc20), IMPLEMENTATION_SLOT);
        address currentImplementationAddress = address(uint160(uint256(currentImplementationRaw)));
        assertEq(currentImplementationAddress, address(newImplementation));
        assertNotEq(currentImplementationAddress, initialImplementationAddress);

        // Verify state is preserved
        assertEq(alloErc20.name(), "Allora");
        assertEq(alloErc20.symbol(), "$ALLO");
        assertEq(alloErc20.owner(), delegate);
        assertEq(alloErc20.ics20Proxy(), address(ics20TransferProxy));

        // Verify we can call new implementation's function
        assertTrue(AlloOFTTestUpgrade(address(alloErc20)).upgradeWorked());
        assertFalse(AlloOFTTestUpgrade(address(alloErc20)).wasUpgradeFunctionCalled());
    }

    function test_upgradeWithFunctionCall() public {
        // Get initial implementation address
        bytes32 implementationRaw = vm.load(address(alloErc20), IMPLEMENTATION_SLOT);
        address initialImplementationAddress = address(uint160(uint256(implementationRaw)));

        // Deploy new implementation
        AlloOFTTestUpgrade newImplementation = new AlloOFTTestUpgrade(address(endpoints[aEid]));

        // Get proxy admin
        ProxyAdmin proxyAdminContract = ProxyAdmin(proxyAdminContractAddress);

        // Cast the proxy to ITransparentUpgradeableProxy
        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(address(alloErc20));

        // Prepare the function call data
        bytes memory upgradeFunctionCall = abi.encodeWithSelector(AlloOFTTestUpgrade.upgradeFunction.selector);

        // Non-owner cannot upgrade
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(this)));
        proxyAdminContract.upgradeAndCall(proxy, address(newImplementation), upgradeFunctionCall);

        // Owner can upgrade and call function
        vm.startPrank(proxyAdmin);
        proxyAdminContract.upgradeAndCall(proxy, address(newImplementation), upgradeFunctionCall);
        vm.stopPrank();

        // Verify new implementation is set
        bytes32 currentImplementationRaw = vm.load(address(alloErc20), IMPLEMENTATION_SLOT);
        address currentImplementationAddress = address(uint160(uint256(currentImplementationRaw)));
        assertEq(currentImplementationAddress, address(newImplementation));
        assertNotEq(currentImplementationAddress, initialImplementationAddress);

        // Verify state is preserved
        assertEq(alloErc20.name(), "Allora");
        assertEq(alloErc20.symbol(), "$ALLO");
        assertEq(alloErc20.owner(), delegate);
        assertEq(alloErc20.ics20Proxy(), address(ics20TransferProxy));

        // Verify the upgrade function was called
        AlloOFTTestUpgrade upgradedContract = AlloOFTTestUpgrade(address(alloErc20));
        assertTrue(upgradedContract.wasUpgradeFunctionCalled());
    }

    // Tests for benchmarking lzReceive and lzCompose
    function test_lzReceive_benchmark() public {
        // Setup similar to existing test
        uint256 tokensToSend = 1 ether;
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        SendParam memory sendParam = SendParam(
            bEid,
            addressToBytes32(userB),
            tokensToSend,
            tokensToSend,
            options,
            "",
            ""
        );
        uint256 initialAlloBalance = 1000 ether;

        // ensure peers have native tokens
        vm.deal(userA, 100 ether);
        vm.deal(userB, 100 ether);

        // Mint tokens to this contract
        ics20TransferProxy.bridgeTokensFromCosmosToEvm(userA, initialAlloBalance);

        for (uint i = 0; i < 500; i++) {
            // Setup for each iteration
            assertEq(alloErc20.balanceOf(userA), initialAlloBalance - i * tokensToSend);
            assertEq(alloErc20OftB.balanceOf(userB), i * tokensToSend);

            MessagingFee memory fee = alloErc20.quoteSend(sendParam, false);
            vm.prank(userA);
            alloErc20.send{ value: fee.nativeFee }(sendParam, fee, payable(address(this)));
            verifyPackets(bEid, addressToBytes32(address(alloErc20OftB)));

            assertEq(alloErc20.balanceOf(userA), initialAlloBalance - (i + 1) * tokensToSend);
            assertEq(alloErc20OftB.balanceOf(userB), (i + 1) * tokensToSend);
        }
    }

    function test_lzCompose_benchmark() public {
        uint256 tokensToSend = 1 ether;
        uint256 initialAlloBalance = 500 ether;

        // Deploy a composer for receiving compose messages
        OFTComposerMock composer = new OFTComposerMock();

        bytes memory options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(200000, 0)
            .addExecutorLzComposeOption(0, 500000, 0);
        bytes memory composeMsg = hex"1234";

        SendParam memory sendParam = SendParam(
            bEid,
            addressToBytes32(address(composer)),
            tokensToSend,
            tokensToSend,
            options,
            composeMsg,
            ""
        );

        // Ensure peers have native tokens
        vm.deal(userA, 100 ether);
        vm.deal(address(composer), 100 ether);

        // Mint tokens to userA
        uint256 amountToMint = initialAlloBalance - alloErc20.balanceOf(userA);
        ics20TransferProxy.bridgeTokensFromCosmosToEvm(userA, amountToMint);

        for (uint i = 0; i < 500; i++) {
            // Setup for each iteration - verify balances before
            assertEq(alloErc20.balanceOf(userA), initialAlloBalance - i * tokensToSend);
            assertEq(alloErc20OftB.balanceOf(address(composer)), i * tokensToSend);

            // Send OFT with compose message
            MessagingFee memory fee = alloErc20.quoteSend(sendParam, false);
            vm.prank(userA);
            (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) = alloErc20.send{ value: fee.nativeFee }(
                sendParam,
                fee,
                payable(address(this))
            );
            verifyPackets(bEid, addressToBytes32(address(alloErc20OftB)));

            // Verify balances after send but before compose
            assertEq(alloErc20.balanceOf(userA), initialAlloBalance - (i + 1) * tokensToSend);
            assertEq(alloErc20OftB.balanceOf(address(composer)), (i + 1) * tokensToSend);

            // Execute lzCompose - this is what we're benchmarking
            bytes memory composerMsg_ = OFTComposeMsgCodec.encode(
                msgReceipt.nonce,
                aEid,
                oftReceipt.amountReceivedLD,
                abi.encodePacked(addressToBytes32(userA), composeMsg)
            );

            this.lzCompose(bEid, address(alloErc20OftB), options, msgReceipt.guid, address(composer), composerMsg_);

            // Verify compose message was processed correctly
            assertEq(composer.from(), address(alloErc20OftB));
            assertEq(composer.guid(), msgReceipt.guid);
            assertEq(composer.message(), composerMsg_);
            assertEq(composer.executor(), address(this));
        }
    }
}
