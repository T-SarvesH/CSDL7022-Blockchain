// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Bank {
    struct client_account {
        int client_id;
        address client_address;
        uint client_balance_in_ether;
    }

    struct FixedDeposit {
        uint amount;
        uint lockPeriod;
        uint interestRate;
    }

    struct Loan {
        uint amount;
        uint interestRate;
        uint totalPayable;
        bool approved;
    }

    client_account[] clients;
    int clientCounter;
    address payable manager;
    mapping(address => uint) public interestDate;
    mapping(address => FixedDeposit) public fixedDeposits;
    mapping(address => Loan) public loans;
    bool isManagerSet = false;

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this!");
        _;
    }

    modifier managerSet(){

        require(isManagerSet == false, "The manager is already set");
        isManagerSet = true;
        _;
    }

    modifier onlyClients() {
        bool isclient = false;
        for (uint i = 0; i < clients.length; i++) {
            if (clients[i].client_address == msg.sender) {
                isclient = true;
                break;
            }
        }
        require(isclient, "Only clients can call this!");
        _;
    }

    constructor() {
        clientCounter = 0;
    }

    receive() external payable {}

    function setManager() public managerSet returns (string memory) {
        manager = payable(msg.sender);
        return "The manager is now set!" ;
    }

    function joinAsClient() public payable returns (string memory) {
        interestDate[payable(msg.sender)] = block.timestamp;
        clients.push(client_account(clientCounter++, msg.sender, address(msg.sender).balance));
        return "";
    }

    function deposit() public payable onlyClients {
        payable(address(this)).transfer(msg.value);
    }

    function withdraw(uint amount) public payable onlyClients {
        payable(msg.sender).transfer(amount * 1 ether);
    }

    function sendInterest() public payable onlyManager {
        for (uint i = 0; i < clients.length; i++) {
            address initialAddress = clients[i].client_address;
            uint lastInterestDate = interestDate[initialAddress];
            if (block.timestamp < lastInterestDate + 10 seconds) {
                revert("It's just been less than 10 seconds!");
            }
            payable(initialAddress).transfer(1 ether);
            interestDate[initialAddress] = block.timestamp;
        }
    }

    function createFixedDeposit(uint _amount, uint lockPeriod) public payable onlyClients {
        require(msg.value == _amount * 1 ether, "Send exact FD amount");
        uint interestRate = 5;

        uint currAmount = fixedDeposits[address(msg.sender)].amount;

        fixedDeposits[msg.sender] = FixedDeposit(currAmount + _amount, lockPeriod, interestRate);
    }

    function grantLoan(address clientAddress) public onlyManager {
        FixedDeposit memory fd = fixedDeposits[clientAddress];
        require(fd.amount > 0, "No FD found for this client");
        uint interestRate = 10;
        uint loanAmount = fd.amount;
        
        uint totalPayable = loanAmount + (loanAmount * interestRate / 100);
        loans[clientAddress] = Loan(loanAmount, interestRate, totalPayable, true);
        payable(clientAddress).transfer(loanAmount * 1 ether);
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
}