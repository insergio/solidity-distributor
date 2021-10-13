//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";


contract Distributor {
    
    address public owner;
    bool public locked;
    
    uint public maxContribution = 10 ether;
    uint public minContribution = 0.1 ether;
    
    mapping(address=>uint) public contributions ;
    uint public contributorsAmount;
    
    
    constructor(){
        owner = msg.sender;
        locked =  true;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner, 'MUST_BE_OWNER');
        _;
    }
    
    function changeMaxContribution (uint amount) public onlyOwner{
        maxContribution = amount;
    }
    
    function changeMinContribution (uint amount) public onlyOwner{
        minContribution = amount;
    }
    
    function transferOwnership(address newOwner) public onlyOwner{
        owner = newOwner;
    }
    
    function unlockWithdrawals() public onlyOwner{
        locked = false;
    }
    
    function contribute() public payable{
        require(msg.value >= minContribution && msg.value <= maxContribution, 'CONTRIBUTION_TOO_LOW');
        require(contributions[msg.sender]+msg.value<maxContribution, 'CONTRIBUTION_TOO_HIGH');
        if(contributions[msg.sender] == 0 ){
            contributorsAmount++;
        }
        contributions[msg.sender]+=msg.value;
    }
    
    function retire() public {
        require(contributions[msg.sender]!=0, 'NO_AVAILABLE_FUNDS');
        (bool success, ) = msg.sender.call{value: (contributions[msg.sender]*9/10)}("");
        contributions[msg.sender]=0;
        require(success, 'COULD NOT RETIRE');
        contributorsAmount--;
    }
    
    function withdraw() public{
        require(locked == false, 'WITHDRAWALS_ARE_LOCKED');
        if(contributions[msg.sender]!=0){
            (bool success, ) = msg.sender.call{value: address(this).balance/contributorsAmount}("");
            require(success, 'COULD_NOT_WITHDRAW');
            contributions[msg.sender]=0;
            contributorsAmount--;
            if(contributorsAmount==0){
                locked = true;
            }
        }

    }

    
}