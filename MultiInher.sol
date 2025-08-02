// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract A {

    string private nameA;
    constructor(string memory _nameA) {
        
        nameA = _nameA;
    }

    function printA() public view returns(string memory){

        return nameA;
    }
 
}

contract B {

    string private nameB;
    constructor(string memory _nameB) {
        
        nameB = _nameB;
    }

    function printB() public view returns(string memory){

        return nameB;
    }  
}

contract MultiInher is A,B {
    
    constructor(string memory _nameA, string memory _nameB) 
        A(_nameA)
        B(_nameB) {}

    function getBoth() public view returns (string memory, string memory) {
        return (printA(), printB());
    }
}