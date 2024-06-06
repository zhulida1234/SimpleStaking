const App = {
  web3: null,
  account: null,
  staking: null,

  start: async function () {
    const { web3 } = this;

    try {
      // 获取用户账户
      const accounts = await web3.eth.getAccounts();
      this.account = accounts[0];

      // 获取网络ID
      const networkId = await web3.eth.net.getId();
      const chainId = await web3.eth.getChainId();
      console.log("Chain ID:", chainId);
      console.info("networkId is", networkId);
      // 获取合约实例
      const stakingArtifact = await fetch('/artifacts/contracts/Stake.sol/Stake.json')
        .then(response => response.json());

      const deployedNetwork = stakingArtifact.networks[networkId];
      if (!deployedNetwork || !deployedNetwork.address) {
        throw new Error(`Contract not deployed on network with ID ${networkId}`);
      }
      this.staking = new web3.eth.Contract(
        stakingArtifact.abi,
        deployedNetwork && deployedNetwork.address,
      );

      const contractAddress = deployedNetwork.address;
      console.log("Contract address:", contractAddress);

      // 将 stake 和 unstake 方法绑定到 window 对象上
      window.stake = this.stake.bind(this);
      window.unstake = this.unstake.bind(this);
    } catch (error) {
      console.error("Could not connect to contract or chain.", error);
    }
  },

  stake: async function () {
    const amount = document.getElementById("stakeAmount").value;
    await this.staking.methods.stake().send({ from: this.account, value: Web3.utils.toWei(amount, "ether") });
  },

  unstake: async function () {
    const amount = document.getElementById("unstakeAmount").value;
    await this.staking.methods.unstake(Web3.utils.toWei(amount, "ether")).send({ from: this.account });
  }
};

window.App = App;

window.addEventListener("load", async function () {
  if (window.ethereum) {
    // 使用 Metamask 的 provider
    App.web3 = new Web3(window.ethereum);
    await window.ethereum.enable();
  } else if (window.web3) {
    // 使用 Mist 或者 Geth 的 provider
    App.web3 = new Web3(window.web3.currentProvider);
  } else {
    console.log('No web3 provider detected');
  }

  App.start();
});