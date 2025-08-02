// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Add{

    int private result;
    int private a;
    int private b;

    constructor(int _a, int _b){

        a = _a;
        b = _b;
        result = add();        
    }

    function add() public view returns (int) {
        return  a + b;
    }

}

