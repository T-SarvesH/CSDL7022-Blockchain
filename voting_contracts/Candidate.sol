// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//For Candidate based data model and its methods
//Would be deployed in a particular timeWindow and after that it would be locked

contract Candidate{

    struct candidate{

        string name;
        string politicalParty;
        bool hasCriminalCase;
        int securityDeposit;
        int age;
        bool isVoter;
    }

    
}