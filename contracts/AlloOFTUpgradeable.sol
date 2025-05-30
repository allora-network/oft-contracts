// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { OFTUpgradeable } from "@layerzerolabs/oft-evm-upgradeable/contracts/oft/OFTUpgradeable.sol";
import { IMintableAndBurnable } from "@cosmos/solidity-ibc-eureka/contracts/interfaces/IMintableAndBurnable.sol";

/**
 * @title AlloOFTUpgradeable
 * @dev Implementation of $ALLO upgradeable OFT
 */
contract AlloOFTUpgradeable is OFTUpgradeable, IMintableAndBurnable {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emitted when the ICS20 proxy address is updated
     * @param oldICS20Proxy Previous ICS20 proxy address
     * @param newICS20Proxy New ICS20 proxy address
     */
    event ICS20ProxyUpdated(address indexed oldICS20Proxy, address indexed newICS20Proxy);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Error thrown when a non-supply admin tries to modify token supply
     */
    error UnauthorizedSupplyAdmin();

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev The address of the ICS20 proxy which facilitates bridging between EVM and Cosmos chains
     */
    address public ics20Proxy;

    constructor(address _lzEndpoint) OFTUpgradeable(_lzEndpoint) {
        _disableInitializers();
    }

    /**
     * @dev Initialize the token
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     * @param _delegate The address of the delegate
     * @param _ics20Proxy The address of the ics20 proxy
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _delegate,
        address _ics20Proxy
    ) public initializer {
        __OFT_init(_name, _symbol, _delegate);
        __Ownable_init(_delegate);

        ics20Proxy = _ics20Proxy;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Only the ics20 proxy can call functions that modify the supply of the token
     * This is only possible when bridging the token between EVM and Cosmos chains
     */
    modifier onlySupplyAdmin() {
        if (msg.sender != ics20Proxy) {
            revert UnauthorizedSupplyAdmin();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Only the owner can update the ICS20 Proxy contract address
     * @param _newICS20Proxy The new address of the ICS20 Proxy contract
     */
    function setICS20Proxy(address _newICS20Proxy) public onlyOwner {
        address oldProxy = ics20Proxy;
        ics20Proxy = _newICS20Proxy;
        emit ICS20ProxyUpdated(oldProxy, _newICS20Proxy);
    }

    /*//////////////////////////////////////////////////////////////
                         OMNICHAIN CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev The shared decimals of the token
     * @return The shared decimals of the token
     */
    function sharedDecimals() public pure override returns (uint8) {
        return 6;
    }

    /*//////////////////////////////////////////////////////////////
                          SUPPLY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Mint new tokens (can only be called by the ICS20 Proxy contract)
     * @param _to The address to mint the tokens to
     * @param _amount The amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external onlySupplyAdmin {
        _mint(_to, _amount);
    }

    /**
     * @dev Burn tokens from an address (can only be called by the ICS20 Proxy contract)
     * @param _from The address to burn the tokens from
     * @param _amount The amount of tokens to burn
     */
    function burn(address _from, uint256 _amount) external onlySupplyAdmin {
        _burn(_from, _amount);
    }
}
