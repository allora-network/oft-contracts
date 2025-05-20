// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { AlloOFTUpgradeable } from "../AlloOFTUpgradeable.sol";

// @dev WARNING: This is for testing purposes only
contract AlloOFTUpgradeableMock is AlloOFTUpgradeable {
    constructor(address _lzEndpoint) AlloOFTUpgradeable(_lzEndpoint) {}

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
