// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libs/SafeArithmetics.sol";

// Minimal CEth interface, see https://etherscan.io/address/0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5#code
interface ICEth {
    function redeem(uint256) external;

    function accrueInterest() external;

    function balanceOfUnderlying(address owner) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}

// Manages an ETH native balance to interact with the Compound protocol: https://compound.finance/docs#getting-started
contract OmniCompoundStrategy {
    using SafeArithmetics for uint256;

    ICEth private CEth;

    // recive function is not defined in the interface, but is required to receive ETH.

    constructor(address _CEth) {
        CEth = ICEth(_CEth);
    }

    // Deposit funds into the Compound ERC20 token
    function deposit() public {
        _send(payable(address(CEth)), address(this).balance);
    }

    // Compound funds acquired from interest on Compound
    function compound() external {
        CEth.accrueInterest();
        // _unlock is intenal, so, already only can be called by self
        // OmniCompoundStrategy(address(this)).unlock();
        _unlock(balance());
        deposit();
    }

    // Allow invocation only by self for compounding
    // function unlock() external {
    //     require(msg.sender == address(this), "INSUFFICIENT_PRIVILEGES");
    //     _unlock(balance());
    // }

    // Calculate total balance
    function balance() public view returns (uint256) {
        return address(this).balance + CEth.balanceOfUnderlying(address(this));
    }

    // this function could be marked as internal in orden to only be called from unlock function
    function _unlock(uint256 amount) internal {
        if (amount > address(this).balance)
            // this arithmetic is too complex
            // can be replaced by ´CEth.redeem(CEth.balanceOf(address(this))´
            // brecause the amount = balance + Underlyinge, and (amount - balance) * CEth.balance / Underlying = CEth.balance
            // is that what is expected to redeem ?
            CEth.redeem(
                (amount - address(this).balance)
                    .safe(
                        SafeArithmetics.Operation.MUL,
                        CEth.balanceOf(address(this))
                    )
                    .safe(
                        SafeArithmetics.Operation.DIV,
                        CEth.balanceOfUnderlying(address(this))
                    )
            );

        _send(payable(msg.sender), amount);
    }

    // this function send Ether to arbitrary destinations
    // how ever address that call compound function will recive the Ether
    function _send(address payable target, uint256 amount) internal {
        // call is the recommended way of sending ETH to other contract
        (bool sent, ) = target.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}
