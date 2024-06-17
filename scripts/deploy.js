const hre = require("hardhat");
const fs = require('fs');
const path = require('path');
const config = require('../configs/config.json');
const { ethers } = hre;



async function main() {

  console.log("hre.network.name",hre.network.name)
  const c = config[hre.network.name];

  console.log("startTime",c.startTime,"endTime",c.endTime,"rewardPerSecond",c.rewardPerSecond,"initiaOwner",c.initialOwner)

  const Stake = await hre.ethers.getContractFactory("Stake");
  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
  const stake = await Stake.deploy(c.initialOwner,ZERO_ADDRESS,ethers.parseEther(c.rewardPerSecond),c.startTime,c.endTime);

  
  await stake.waitForDeployment();
  console.log("stake instance :", stake)

  const address = stake.target;

  console.log("Staking contract deployed to:", address);

  // 获取网络ID
  const networkId = await hre.network.provider.send("net_version");

  // 读取现有的 Stake.json 文件
  const artifactPath = path.join(__dirname, '../artifacts/contracts/Stake.sol/Stake.json');
  const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));

  // 添加或更新网络信息
  if (!artifact.networks) {
    artifact.networks = {};
  }
  artifact.networks[networkId] = { address: address };

  // 将更新后的信息写回到 Stake.json 文件中
  fs.writeFileSync(artifactPath, JSON.stringify(artifact, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });