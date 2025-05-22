// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { OFTTest } from "@layerzerolabs/oft-evm-upgradeable/test/OFT.t.sol";
import { EndpointV2Mock } from "@layerzerolabs/test-devtools-evm-foundry/contracts/mocks/EndpointV2Mock.sol";
import { AlloOFTUpgradeable, IMintableAndBurnable } from "../../contracts/AlloOFTUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";


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


contract AlloOFTUpgradeableTest is OFTTest {
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    AlloOFTUpgradeable alloErc20;
    MockICS20TransferProxy ics20TransferProxy;

    address delegate = makeAddr("delegate");
    address proxyOwner = makeAddr("proxyOwner");

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public override {
      super.setUp();

      
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
      ics20TransferProxy.setMintableBurnableToken(address(alloErc20));
      vm.stopPrank();
    }

    // ================================
    // Implementation tests
    // ================================

    function test_alloErc20Deployment() public {
      assertEq(alloErc20.owner(), delegate);
      assertEq(address(alloErc20.ics20Proxy()), address(ics20TransferProxy));
      // ERC20 details
      assertEq(alloErc20.name(), "Allora");
      assertEq(alloErc20.symbol(), "$ALLO");
      assertEq(alloErc20.decimals(), 18);
      assertEq(alloErc20.totalSupply(), 0);
      // OFT details
      assertEq(alloErc20.sharedDecimals(), 6);
      assertEq(address(alloErc20.endpoint()), address(endpoints[aEid]));
    }

    function test_ics20TransferProxyCanMint() public {
      assertEq(alloErc20.balanceOf(address(this)), 0);

      vm.expectEmit(true, true, true, true);
      emit Transfer(address(0), address(this), 100);
      ics20TransferProxy.bridgeTokensFromCosmosToEvm(address(this), 100);
      assertEq(alloErc20.balanceOf(address(this)), 100);
    }

    function test_ics20TransferProxyCanBurn() public {
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
      alloErc20.mint(address(this), 100);
    }

    function test_EOABurnFails() public {
      // Mint 100 tokens
      ics20TransferProxy.bridgeTokensFromCosmosToEvm(address(this), 100);
      assertEq(alloErc20.balanceOf(address(this)), 100);

      vm.expectRevert(AlloOFTUpgradeable.UnauthorizedSupplyAdmin.selector);
      alloErc20.burn(address(this), 100);
    }

    function test_ownerCanChangeIcs20Proxy() public {
      address contractOwner = alloErc20.owner();
      MockICS20TransferProxy2 newIcs20TransferProxy = new MockICS20TransferProxy2();

      vm.startPrank(contractOwner);
      alloErc20.setICS20Proxy(address(newIcs20TransferProxy));
      vm.stopPrank();
      assertEq(address(alloErc20.ics20Proxy()), address(newIcs20TransferProxy));
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
