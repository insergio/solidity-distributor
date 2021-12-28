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

    event userChange(address indexed _account, uint256 amount);
    event contractChange();
    
    constructor(){
        owner = msg.sender;
        locked =  true;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner, 'MUST_BE_OWNER');
        _;
    }
    
    function changeMaxContribution (uint amount) external onlyOwner{
        maxContribution = amount;
        emit contractChange();
    }
    
    function changeMinContribution (uint amount) external onlyOwner{
        minContribution = amount;
        emit contractChange();
    }
    
    function transferOwnership(address newOwner) external onlyOwner{
        require(address(newOwner) != address(0), 'ADDRESS_CANT_BE_ZERO');   
        owner = newOwner;
        emit contractChange();
    }
    
    function unlockWithdrawals() external onlyOwner{
        locked = false;
        emit contractChange();
    }
    
    function contribute() external payable{
        require(msg.value >= minContribution && msg.value <= maxContribution, 'CONTRIBUTION_TOO_LOW');
        require(contributions[msg.sender]+msg.value<maxContribution, 'CONTRIBUTION_TOO_HIGH');
        if(contributions[msg.sender] == 0 ){
            contributorsAmount++;
        }
        contributions[msg.sender]+=msg.value;
        emit userChange(msg.sender, contributions[msg.sender]);
    }
    
    function retire() external {
        require(contributions[msg.sender]!=0, 'NO_AVAILABLE_FUNDS');
        uint currentContribution = contributions[msg.sender];
        contributions[msg.sender]=0;
        contributorsAmount--;
        (bool success, ) = msg.sender.call{value: (currentContribution*9/10)}("");
        emit userChange(msg.sender, contributions[msg.sender]);
        require(success, 'COULD NOT RETIRE');
    }
    
    function withdraw() external{
        require(locked == false, 'WITHDRAWALS_ARE_LOCKED');
        if(contributions[msg.sender]!=0){
            contributions[msg.sender]=0;
            uint currentContributors = contributorsAmount;
            contributorsAmount--;
            if(contributorsAmount==0){
                locked = true;
            }
            (bool success, ) = msg.sender.call{value: address(this).balance/currentContributors}("");
            emit userChange(msg.sender, contributions[msg.sender]);
            require(success, 'COULD_NOT_WITHDRAW');   
        }
    }
}