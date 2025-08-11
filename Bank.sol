// SPDX-License-Identifier: MIT

//Sarvesh Tikekar Roll no: 64

pragma solidity ^0.8.20;

contract Bank {

    //Structs for ease
    struct client_account {
        int client_id;
        address client_address;
        uint client_balance_in_ether;
    }

    struct FixedDeposit {
        uint amount;
        uint256 lockPeriod;
        uint interestRate;
    }

    struct Loan {
        uint amount;
        uint interestRate;
        uint totalPayable;
        uint256 timePeriod;
        bool approved;
    }

    client_account[] clients;
    int clientCounter;
    address payable manager;
    mapping(address => uint) public interestDate;
    mapping(address => FixedDeposit) public fixedDeposits;
    mapping(address => Loan) public loans;
    bool isManagerSet = false;

    //Some manager modifiers
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

    //Once manager set it can't be changed
    function setManager() public managerSet returns (string memory) {
        manager = payable(msg.sender);
        return "The manager is now set!";
    }

    function joinAsClient() public payable returns (client_account memory) {
        interestDate[payable(msg.sender)] = block.timestamp;
        client_account memory Client = client_account(clientCounter++, msg.sender, address(msg.sender).balance);

        clients.push(Client);
        return Client;
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

    modifier isBeyondLockPeriod(){

        uint lockP = fixedDeposits[address(msg.sender)].lockPeriod;

        //If FD exists and its lockPeriod has expired so the client can access the FD now
        require(lockP > 0 && lockP < block.timestamp, "Lock period isnt over yet so you need to wait");
        _;
    }

    modifier isExactAmount(uint _amount){

        uint amt = fixedDeposits[address(msg.sender)].amount;
        require(amt == _amount, "Amount sent to FD is not exact");
        _;
    }

    function createFixedDeposit(uint _amount, uint lockPeriod) public payable onlyClients returns (FixedDeposit memory){

        uint interestRate = 5;
        fixedDeposits[msg.sender] = FixedDeposit(_amount, lockPeriod + block.timestamp, interestRate);

        return fixedDeposits[msg.sender];

    }

    function updateFixedDeposit(uint _amount, uint lockPeriod) public payable onlyClients isExactAmount(_amount) isBeyondLockPeriod returns(string memory){

        uint interestRate = 5;
        uint currAmount = fixedDeposits[address(msg.sender)].amount;

        fixedDeposits[msg.sender] = FixedDeposit(currAmount + _amount, lockPeriod, interestRate);
        return "Fixed Deposited Updated";
    }

    modifier doesFDexists(address client){
        uint amt = fixedDeposits[client].amount;
        require(amt > 0, "This FD doesnt exist");
        _;
    }

    function grantLoan(address clientAddress, uint _timeperiod) public payable onlyManager doesFDexists(clientAddress) returns (uint){
        FixedDeposit memory fd = fixedDeposits[clientAddress];
        uint interestRate = 10;
        uint prevLoanamt = loans[address(clientAddress)].amount;
        uint loanAmount = fd.amount;
        uint _totalPayable = loans[address(clientAddress)].totalPayable;
        _totalPayable += (loanAmount + (loanAmount * interestRate / 100));

        loans[clientAddress] = Loan(loanAmount + prevLoanamt, interestRate, _totalPayable, _timeperiod ,true);
        payable(clientAddress).transfer(loanAmount);
        return (msg.sender.balance * 1 ether);
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
}