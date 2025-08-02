// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Prime {
    
    int private number;
    string private ans;

    constructor(int _number) {
        
        number = _number;
        ans = isPrime();
    }

    function isPrime() public view returns (string memory){

        if(number < 1)
        return "Not Prime";

        for (int i=2; i < number; ++i){

            if(number % i == 0)
            return "Not Prime";
        }

        return "Prime";
    }
}