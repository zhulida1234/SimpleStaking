// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Stake{

    mapping(address => uint256) public stakes;
    address[] public stakers;
    uint256 public totalStakes;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);


    function stake() external payable {
        require(msg.value > 0, "Cannot stake 0 Ether");
        if (stakes[msg.sender] == 0) {
            stakers.push(msg.sender);
        }
        stakes[msg.sender] += msg.value;
        totalStakes += msg.value;
        emit Staked(msg.sender, msg.value);
    }

    function unstake(uint256 amount) external {
        require(stakes[msg.sender] >= amount, "Insufficient stake");
        stakes[msg.sender] -= amount;
        totalStakes -= amount;
        payable(msg.sender).transfer(amount);
        emit Unstaked(msg.sender, amount);
    }

    function getStakers() external view returns (address[] memory) {
        return stakers;
    }


}