// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MetaMask {
    
    event output (string message);
    function metamask() public {

        emit output("The contract is running and is connected to MetaMask");
    }

}