const hre = require("hardhat");
const fs = require('fs');
const path = require('path');

async function main() {
  const Stake = await hre.ethers.getContractFactory("Stake");
  const stake = await Stake.deploy();

  
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