// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MetaMaskPayable{

    event output (uint amount, address sender, string message);
    event bal (address contractAddress, uint balance);

    //Make a transaction function to transfer Sepolia ETH to contract
    function metamaskTransaction(uint _value, address _sender) public payable {
        require(_value * 1 ether == msg.value, "The amount in message and which is sent isnt correct");
        require(msg.sender == _sender, "The Sender's address isnt correct");

        emit output(uint(_value * 1 ether), address(msg.sender), 
        "The sender has successfully deposited the amount in the contract");

        emit bal (address(this), address(this).balance);
    } 
}