import { ethers } from "./ethers-5.6.esm.min.js";
import { factoryAbi, delegatorAbi, factoryAddress } from "./constants.js";

const urlParams = new URLSearchParams(window.location.search);
const delegatorAddress = urlParams.get("address");

const connectButton = document.getElementById("connectButton");

const projectNameLabel = document.getElementById("projectName");
const tokenSymbolLabel = document.getElementById("tokenSymbol");

const sponsoredNameLabel = document.getElementById("sponsoredName");
const sponsoredAddressLabel = document.getElementById("sponsoredAddress");
const sponsoredUrlLabel = document.getElementById("sponsoredURL");
const sponsorAmountLabel = document.getElementById("sponsorAmount");
const rewardShareAmountLabel = document.getElementById("rewardShareAmount");
const poolTotalSupplyAmountLabel = document.getElementById(
  "poolTotalSupplyAmount"
);

const aAVeTotalSupplyAmountLabel = document.getElementById(
  "aAVeTotalSupplyAmount"
);

const rewardGiveBackAmountLabel = document.getElementById(
  "rewardGiveBackAmount"
);

const accumulationInterestAmountLabel = document.getElementById(
  "accumulationInterestAmount"
);

const mintButton = document.getElementById("mintButton");
const redeemButton = document.getElementById("redeemButton");
const transferButton = document.getElementById("transferButton");
const approveButton = document.getElementById("approveButton");
const rewardGiveBackClaimButton = document.getElementById(
  "rewardGiveBackClaimButton"
);
const giveBackButton = document.getElementById("giveBackButton");
const accumulationInterestClaimButton = document.getElementById(
  "accumulationInterestClaimButton"
);

connectButton.onclick = connect;
mintButton.onclick = mint;
redeemButton.onclick = redeem;

transferButton.onclick = transfer;
approveButton.onclick = approve;
rewardGiveBackClaimButton.onclick = claimReward;
giveBackButton.onclick = giveback;
accumulationInterestClaimButton.onclick = claimInterest;

async function connect() {
  if (typeof window.ethereum !== "undefined") {
    try {
      await ethereum.request({ method: "eth_requestAccounts" });
    } catch (error) {
      console.log(error);
    }
    connectButton.innerHTML = "Connected";
    const accounts = await ethereum.request({ method: "eth_accounts" });
    console.log(accounts);
  } else {
    connectButton.innerHTML = "Please install MetaMask";
  }
}

async function updateStatus() {
  if (typeof window.ethereum !== "undefined") {
    connectButton.innerHTML = "Connected";
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      delegatorAddress,
      delegatorAbi,
      signer
    );

    const projectName = await contract.name();
    projectNameLabel.innerHTML = projectName;
    const tokenSymbol = await contract.symbol();
    tokenSymbolLabel.innerHTML = tokenSymbol;
    const name = await contract.sponseredName();
    sponsoredNameLabel.innerHTML = name;
    const sponsoredAddress = await contract.sponsoredAddr();
    sponsoredAddressLabel.innerHTML = sponsoredAddress;
    const sponsoredUrl = await contract.sponseredURI();
    sponsoredUrlLabel.innerHTML = sponsoredUrl;

    let accounts = await provider.send("eth_requestAccounts", []);
    let account = accounts[0];

    const sponsorAmount = await contract.balanceOf(account);
    sponsorAmountLabel.textContent = ethers.utils.formatEther(sponsorAmount);

    const rewardShareAmount = await contract.sponsorAccumulationShare(account);
    rewardShareAmountLabel.textContent =
      ethers.utils.formatEther(rewardShareAmount);

    const poolTotalSupplyAmount = await contract.totalSupply();
    poolTotalSupplyAmountLabel.textContent = ethers.utils.formatEther(
      poolTotalSupplyAmount
    );

    const rewardAccumulatAmount = await contract.waitForGiverClaimAmount(
      account
    );

    rewardGiveBackAmountLabel.textContent = ethers.utils.formatEther(
      rewardAccumulatAmount
    );

    // Fail on local Anvil (Can't get info from AAVE)
    const aAVeTotalSupplyAmount = await contract.supplyBalance();
    aAVeTotalSupplyAmountLabel.textContent = ethers.utils.formatEther(
      aAVeTotalSupplyAmount
    );

    const accumulationInterestAmount =
      aAVeTotalSupplyAmount - poolTotalSupplyAmount;
    accumulationInterestAmountLabel.textContent = ethers.utils.formatEther(
      accumulationInterestAmount
    );
  } else {
    connectButton.innerHTML = "Please install MetaMask";
  }
}

function listenForTransactionMine(transactionResponse, provider) {
  console.log(`Mining ${transactionResponse.hash}`);
  return new Promise((resolve, reject) => {
    provider.once(transactionResponse.hash, (transactionReceipt) => {
      console.log(
        `Completed with ${transactionReceipt.confirmations} confirmations. `
      );
      resolve();
      location.reload();
    });
  });
}

async function mint() {
  const ethAmount = document.getElementById("mintAmount").value;
  console.log(`Mint with ${ethAmount}...`);
  if (typeof window.ethereum !== "undefined") {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      delegatorAddress,
      delegatorAbi,
      signer
    );

    try {
      const accounts = await ethereum.request({ method: "eth_accounts" });
      console.log(accounts);

      const balance = await provider.getBalance(accounts[0]);
      console.log(ethers.utils.formatEther(balance));

      const transactionResponse = await contract.mint({
        value: ethers.utils.parseEther(ethAmount),
      });
      await listenForTransactionMine(transactionResponse, provider);
    } catch (error) {
      console.log(error);
    }
  } else {
    mintButton.innerHTML = "Please install MetaMask";
  }
}

async function redeem() {
  const ethAmount = document.getElementById("redeemAmount").value;
  console.log(`Redeem with ${ethAmount}...`);
  if (typeof window.ethereum !== "undefined") {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      delegatorAddress,
      delegatorAbi,
      signer
    );

    try {
      const transactionResponse = await contract.redeem(
        ethers.utils.parseEther(ethAmount)
      );
      await listenForTransactionMine(transactionResponse, provider);
    } catch (error) {
      console.log(error);
    }
  } else {
    redeemButton.innerHTML = "Please install MetaMask";
  }
}

async function withdraw() {
  console.log(`Withdrawing...`);
  if (typeof window.ethereum !== "undefined") {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(contractAddress, abi, signer);
    try {
      const transactionResponse = await contract.withdraw();
      await listenForTransactionMine(transactionResponse, provider);
      // await transactionResponse.wait(1)
    } catch (error) {
      console.log(error);
    }
  } else {
    withdrawButton.innerHTML = "Please install MetaMask";
  }
}

async function fund() {
  const ethAmount = document.getElementById("ethAmount").value;
  console.log(`Funding with ${ethAmount}...`);
  if (typeof window.ethereum !== "undefined") {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(contractAddress, abi, signer);
    try {
      const transactionResponse = await contract.fund({
        value: ethers.utils.parseEther(ethAmount),
      });
      await listenForTransactionMine(transactionResponse, provider);
    } catch (error) {
      console.log(error);
    }
  } else {
    fundButton.innerHTML = "Please install MetaMask";
  }
}

async function transfer() {
  console.log("transfer");
  const ethAmount = document.getElementById("transferAmount").value;
  const transferTo = document.getElementById("transferTo").value;

  console.log(`Transfer ${ethAmount} to ${transferTo}`);
  if (typeof window.ethereum !== "undefined") {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      delegatorAddress,
      delegatorAbi,
      signer
    );
    try {
      const transactionResponse = await contract.transfer(
        transferTo,
        ethers.utils.parseEther(ethAmount)
      );
      await listenForTransactionMine(transactionResponse, provider);
    } catch (error) {
      console.log(error);
    }
  } else {
    transferButton.innerHTML = "Please install MetaMask";
  }
}
async function approve() {
  console.log("Approve");
  const ethAmount = document.getElementById("approveAmount").value;
  const approveTo = document.getElementById("approveTo").value;

  console.log(`Approve ${ethAmount} to ${approveTo}`);
  if (typeof window.ethereum !== "undefined") {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      delegatorAddress,
      delegatorAbi,
      signer
    );
    try {
      const transactionResponse = await contract.approve(
        approveTo,
        ethers.utils.parseEther(ethAmount)
      );
      await listenForTransactionMine(transactionResponse, provider);
    } catch (error) {
      console.log(error);
    }
  } else {
    approveButton.innerHTML = "Please install MetaMask";
  }
}
async function claimReward() {
  console.log("claimReward");
  const ethAmount = document.getElementById("rewardGiveBackAmount").value;

  console.log(`claimReward ${ethAmount}`);
  if (typeof window.ethereum !== "undefined") {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      delegatorAddress,
      delegatorAbi,
      signer
    );
    try {
      const transactionResponse =
        await contract.sponsorClaimWaitGiveBackAmount();
      await listenForTransactionMine(transactionResponse, provider);
    } catch (error) {
      console.log(error);
    }
  } else {
    rewardGiveBackClaimButton.innerHTML = "Please install MetaMask";
  }
}
async function giveback() {
  console.log("giveback");
  const ethAmount = document.getElementById("giveBackAmount").value;

  console.log(`giveback ${ethAmount}`);
  if (typeof window.ethereum !== "undefined") {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      delegatorAddress,
      delegatorAbi,
      signer
    );
    try {
      const transactionResponse = await contract.giveback({
        value: ethers.utils.parseEther(ethAmount),
      });
      await listenForTransactionMine(transactionResponse, provider);
    } catch (error) {
      console.log(error);
    }
  } else {
    giveBackButton.innerHTML = "Please install MetaMask";
  }
}
async function claimInterest() {
  console.log("claimInterest");
  const ethAmount = document.getElementById("accumulationInterestAmount").value;

  console.log(`claimInterest ${ethAmount}`);
  if (typeof window.ethereum !== "undefined") {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(
      delegatorAddress,
      delegatorAbi,
      signer
    );
    try {
      const transactionResponse = await contract.claimInterest();
      await listenForTransactionMine(transactionResponse, provider);
    } catch (error) {
      console.log(error);
    }
  } else {
    accumulationInterestClaimButton.innerHTML = "Please install MetaMask";
  }
}

window.onload = async function () {
  console.log("Auto run!!!");
  updateStatus();
};
