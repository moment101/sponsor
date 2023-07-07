import { ethers } from "./ethers-5.6.esm.min.js";
import { factoryAbi, delegatorAbi, factoryAddress } from "./constants.js";

const urlParams = new URLSearchParams(window.location.search);
const delegatorAddress = urlParams.get("address");

const connectButton = document.getElementById("connectButton");
const sponsorNameLabel = document.getElementById("sponsorName");
const sponsorUrlLabel = document.getElementById("sponsorUrl");
const sponsorAddressLabel = document.getElementById("sponsorAddress");
const sponsorAmountLabel = document.getElementById("sponsorAmount");
const sponsorTotalAmountLabel = document.getElementById("sponsorTotalAmount");

const mintButton = document.getElementById("mintButton");
const redeemButton = document.getElementById("redeemButton");

connectButton.onclick = connect;
mintButton.onclick = mint;
redeemButton.onclick = redeem;

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
    const name = await contract.sponseredName();
    sponsorNameLabel.textContent = name;

    const sponsorUrl = await contract.sponseredURI();
    sponsorUrlLabel.textContent = sponsorUrl;

    const sponsorAddress = await contract.sponsoredAddr();
    sponsorAddressLabel.textContent = sponsorAddress;

    const sponsorAmount = await contract.balanceOf(signer.getAddress());
    console.log(signer.getAddress());
    sponsorAmountLabel.textContent = ethers.utils.formatEther(sponsorAmount);

    const sponsorTotalAmount = await contract.totalSupply();
    sponsorTotalAmountLabel.textContent =
      ethers.utils.formatEther(sponsorTotalAmount);
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

window.onload = async function () {
  console.log("Auto run!!!");
  updateStatus();
};
