// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Stake is Ownable{

    using SafeERC20 for IERC20;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    IERC20 public erc20;
    // 活动开始时间
    uint256 public startTimeStamp;
    // 活动结束时间
    uint256 public endTimeStamp;
    // 总的奖励金额
    uint256 public totalRewards;
    // 总的已支付出去的奖励
    uint256 public paidOut;
    // 流动性代币池子
    PoolInfo[] pools;
    // 每秒的奖励数量
    uint256 public rewardPerSecond;
    // 总分配的点数
    uint256 public totalAllocPoint;

    mapping(uint => mapping(address => User)) public  userInfo;
    
    struct User{
        uint256 amount;  // 为流动性池子提供的股数
        uint256 rewardDebt;  //奖励账单
    }

    struct PoolInfo{
        IERC20 lpToken;
        uint256 lastRewardTimeStamp;
        uint256 allocPoint;
        uint256 accERC20PerShare;
        uint256 totalDeposite;
    }

    constructor (address initialOwner,IERC20 _erc20,uint256 _rewardPerSecond,uint256 _startTimeStamp,uint256 _endTimeStamp) Ownable(initialOwner) {
        erc20 = _erc20;
        rewardPerSecond = _rewardPerSecond;
        startTimeStamp = _startTimeStamp;
        endTimeStamp = _endTimeStamp;
    }

    function poolLength() internal view returns (uint256) {
        return pools.length;
    }

    //为池子注入资金
    function fund(uint256 _amount) public {
        require(block.timestamp < endTimeStamp,"the time is too late,it was end");
        totalRewards += _amount;
        endTimeStamp += _amount/(rewardPerSecond);
        // erc20.safeTransferForm(address(msg.sender), address(this), _amount);
        erc20.safeTransferFrom(msg.sender,address(this), _amount);
    } 

    //给池子增加一个流动性提供者 
    function add(IERC20 _token,uint256 _allocPoint,bool _withUpdate) external onlyOwner {
        if(_withUpdate){
            massUpdatePools();
        }
        uint256 lastRewardTimeStamp = block.timestamp > startTimeStamp ? block.timestamp : startTimeStamp;
        totalAllocPoint += _allocPoint;
        pools.push(PoolInfo({lpToken:_token,allocPoint:_allocPoint,lastRewardTimeStamp:lastRewardTimeStamp,accERC20PerShare:0,totalDeposite:0}));
    }
    
    //给指定的池子重新设置分配点数
    function set(uint256 _pid,uint256 _allocPoint,bool _withUpdate) external onlyOwner {
        if(_withUpdate){
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint-pools[_pid].allocPoint+_allocPoint;
        pools[_pid].allocPoint = _allocPoint;
    
    }

    //查看指定的用户提供了多少的LP
    function deposited(address _user,uint256 _pid) external view returns (uint256) {
        return userInfo[_pid][_user].amount;
    }

    //查看指定用户,在指定池子里面的待领取代币奖励
    function pending(uint _pid,address _user) internal view returns (uint256){
        User storage user = userInfo[_pid][_user];
        PoolInfo storage poolInfo = pools[_pid];
        uint256 accERC20PerShare = poolInfo.accERC20PerShare;
        uint256 totalSupply = poolInfo.totalDeposite;
        if(block.timestamp > poolInfo.lastRewardTimeStamp && totalSupply > 0){
            uint256 lastTime = block.timestamp < endTimeStamp ? block.timestamp : endTimeStamp;
            uint256 compareLastRewardTime = poolInfo.lastRewardTimeStamp < endTimeStamp ? poolInfo.lastRewardTimeStamp : endTimeStamp;
            uint256 effectTime = lastTime - compareLastRewardTime;
            uint256 reward = rewardPerSecond*effectTime*poolInfo.allocPoint/(totalAllocPoint);
            accERC20PerShare = accERC20PerShare+(reward*(1e36)/(totalSupply));
        }

        return user.amount*(accERC20PerShare)/(1e36)-(user.rewardDebt);
    }

    //查看总的待领取奖励 (每秒的奖励 * 累积时间 - 已经支付的奖励金额)
    //取当前时间 和 endTime间较小的那个
    function totalPending() external view returns (uint256){
        if(block.timestamp < startTimeStamp){
            return 0;
        }

        uint256 lastTime = block.timestamp < endTimeStamp ? block.timestamp:endTimeStamp;
        uint256 effectTime = lastTime - startTimeStamp;

        return effectTime*(rewardPerSecond)-(paidOut);

    }

    //全量更新所有流动性池子
    function massUpdatePools() internal  {
        uint256 length = pools.length;
        for(uint i=0;i<length;i++){
            updatePool(i);
        }
    }

    //更新单个的流动性池子
    function updatePool(uint256 _pid) internal  {
        PoolInfo storage poolInfo = pools[_pid];
        uint256 lastTime = block.timestamp < endTimeStamp ? block.timestamp : endTimeStamp;
        if(lastTime <= poolInfo.lastRewardTimeStamp){
            return;
        }
        uint256 totalSupply = poolInfo.totalDeposite;
        if(totalSupply == 0){
            poolInfo.lastRewardTimeStamp = lastTime;
            return;
        }
        // 计算持续时间
        uint256 effectTime = lastTime - poolInfo.lastRewardTimeStamp;
        uint256 accERC20PerShare = poolInfo.accERC20PerShare;

        uint256 reward = rewardPerSecond*(effectTime)*(poolInfo.allocPoint)/(totalAllocPoint);
        accERC20PerShare = accERC20PerShare+(reward*(1e36)/(totalSupply));

        poolInfo.accERC20PerShare = accERC20PerShare;
        poolInfo.lastRewardTimeStamp = block.timestamp;
    }

    // 给指定的地址进行转账
    function transferTo(address _to,uint256 _amount) internal {
        erc20.transfer(_to,_amount);
        paidOut += _amount;
    }

    function stake(uint256 _pid,uint256 _amount) external {
        User storage user = userInfo[_pid][msg.sender];
        PoolInfo storage pool = pools[_pid];

        if(user.amount>0){
            //获取当前应当领取的奖励
            uint256 pendingAmount = pending(_pid,msg.sender);

            //发送给当前的操作账户
            transferTo(msg.sender,pendingAmount);
        }
        updatePool(_pid);
        //给当前合约转账
        pool.lpToken.safeTransferFrom(msg.sender,address(this),_amount);
        pool.totalDeposite += _amount;

        user.amount +=_amount;
        user.rewardDebt = user.amount*(pool.accERC20PerShare)/(1e36);

    }

    function unstake(uint256 _pid,uint256 _amount) external {
        
        User storage user = userInfo[_pid][msg.sender];
        require(_amount <= user.amount,"unstake amount must be little then user provider");
        PoolInfo storage pool = pools[_pid];

        updatePool(_pid);

        uint256 pendingAmount = pending(_pid,msg.sender);
        transferTo(msg.sender,pendingAmount);

        pool.lpToken.safeTransfer(msg.sender,_amount);

        pool.totalDeposite -= _amount;

        user.amount -= _amount;
        user.rewardDebt = user.amount*(pool.accERC20PerShare)/(1e36);

    }


}