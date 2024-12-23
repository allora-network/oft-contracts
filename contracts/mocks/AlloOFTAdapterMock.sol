// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { AlloOFTAdapter } from "../AlloOFTAdapter.sol";

// @dev WARNING: This is for testing purposes only
contract AlloOFTAdapterMock is AlloOFTAdapter {
    constructor(
        address _token,
        address _lzEndpoint,
        address _delegate
    ) AlloOFTAdapter(_token, _lzEndpoint, _delegate) {}
}
