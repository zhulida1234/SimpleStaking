// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Demo{

    function getMsgSender() external view returns(address){
        return msg.sender;
    }

}