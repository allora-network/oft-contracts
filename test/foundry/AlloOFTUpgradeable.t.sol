// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { OFTTest } from "@layerzerolabs/oft-evm-upgradeable/test/OFT.t.sol";
import { EndpointV2Mock } from "@layerzerolabs/test-devtools-evm-foundry/contracts/mocks/EndpointV2Mock.sol";
import { AlloOFTUpgradeable, IMintableAndBurnable } from "../../contracts/AlloOFTUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { console } from "forge-std/console.sol";

contract MockICS20TransferProxy {
  IMintableAndBurnable public mintableBurnableToken;

  // @dev This is a mock function for showcasing triggering the burn function on the AlloOFTUpgradeable contract
  function bridgeTokensFromEvmToCosmos(address _from, uint256 _amount) public {
    mintableBurnableToken.burn(_from, _amount);
  }

  // @dev This is a mock function for showcasing triggering the mint function on the AlloOFTUpgradeable contract
  function bridgeTokensFromCosmosToEvm(address _to, uint256 _amount) public {
    console.log("bridgeTokensFromCosmosToEvm", _to, _amount);
    mintableBurnableToken.mint(_to, _amount);
  }

  function setMintableBurnableToken(address _mintableBurnableToken) public {
    mintableBurnableToken = IMintableAndBurnable(_mintableBurnableToken);
  }
}

contract MockICS20TransferProxy2 is MockICS20TransferProxy {}


contract AlloOFTUpgradeableTest is OFTTest {
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    AlloOFTUpgradeable alloErc20;
    MockICS20TransferProxy ics20TransferProxy;

    address delegate = makeAddr("delegate");
    address proxyOwner = makeAddr("proxyOwner");

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
      vm.startPrank(proxyOwner);
      ics20TransferProxy = new MockICS20TransferProxy();
      alloErc20 = AlloOFTUpgradeable(
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

      // Set the mintableBurnableToken address in the ICS20TransferProxy contract
      ics20TransferProxy.setMintableBurnableToken(address(alloErc20));
      vm.stopPrank();
    }

    // ================================
    // Implementation tests
    // ================================

    function test_alloErc20Deployment() public view {
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
        AlloOFTUpgradeable oftUpgradeable = AlloOFTUpgradeable(
            _deployContractAndProxy(
                type(AlloOFTUpgradeable).creationCode,
                abi.encode(address(endpoints[aEid])),
                abi.encodeWithSelector(
                    AlloOFTUpgradeable.initialize.selector,
                    "Allora",
                    "$ALLO",
                    address(this),
                    address(0)
                )
            )
        );

        bytes32 implementationRaw = vm.load(address(oftUpgradeable), IMPLEMENTATION_SLOT);
        address implementationAddress = address(uint160(uint256(implementationRaw)));

        AlloOFTUpgradeable oftUpgradeableImplementation = AlloOFTUpgradeable(implementationAddress);

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        oftUpgradeableImplementation.initialize("Allora", "$ALLO", address(this), address(0));

        EndpointV2Mock endpoint = EndpointV2Mock(address(oftUpgradeable.endpoint()));
        assertEq(endpoint.delegates(address(oftUpgradeable)), address(this));
        assertEq(endpoint.delegates(implementationAddress), address(0));
    }

}
