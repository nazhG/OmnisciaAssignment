// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// The Omni Token for the rewards distributed by OmniChef
contract Omni is ERC20, Ownable {
    // this number too long, can cause confusion in the future
    // https://docs.soliditylang.org/en/latest/units-and-global-variables.html#ether-units
    uint256 internal constant INITIAL_SUPPLY = 1e7;
    // could be marked as immutable
    address public immutable emergencyAdmin;

    constructor(
        string memory name,
        string memory symbol,
        address omniChef
    ) ERC20(name, symbol) Ownable() {
        // Set emergency administrator in case OmniStaking becomes unresponsive
        emergencyAdmin = tx.origin;

        // Mint initial reward supply to the OmniChef
        // use * intead of ^ to mul the initial supply by 1e18
        // ^ is a logical xor operator and not a math operator
        _mint(omniChef, INITIAL_SUPPLY * decimals());

        // Transfer ownership to OmniChef for migration purposes
        _transferOwnership(omniChef);
    }

    // this function could be marked as external
    // remove previousOwner parameter because can used to transfer from any address
    // rename argument to newOwner for better understanding
    function upgrade(address newOwner) external {
        // Emergency Administrator in case OmniChef malfunctions
        require(
            // should use the ownwer function instead of argument sended
            Ownable.owner() == msg.sender || emergencyAdmin == msg.sender,
            "INSUFFICIENT_PRIVILEDGES"
        );

        // Transfer remaining rewards
        _transfer(Ownable.owner(), newOwner, balanceOf(Ownable.owner()));

        // Transfer ownership to new OmniChef
        _transferOwnership(newOwner);
    }
}
