// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { OFTTest } from "@layerzerolabs/oft-evm-upgradeable/test/OFT.t.sol";
import { EndpointV2Mock } from "@layerzerolabs/test-devtools-evm-foundry/contracts/mocks/EndpointV2Mock.sol";
import { AlloOFTUpgradeable } from "../../contracts/AlloOFTUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AlloOFTUpgradeableTest is OFTTest {
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function test_oft_implementation_initialization_disabled() public {
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
