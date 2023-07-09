import { ethers } from "./ethers-5.6.esm.min.js";
import { factoryAbi, factoryAddress } from "./constants.js";

const connectButton = document.getElementById("connectButton");
const createButton = document.getElementById("createButton");

connectButton.onclick = connect;
createButton.onclick = createProject;

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

async function queryProjectList() {
  if (typeof window.ethereum !== "undefined") {
    connectButton.innerHTML = "Connected";
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(factoryAddress, factoryAbi, signer);
    const summary = await contract.summaryAllProjects();
    console.log(summary);

    const number = await contract.projectNumber();
    console.log(number.toNumber());

    var tableData = [];
    for (var i = 0; i < summary.length; i++) {
      const addr = await contract.allProjects(i);
      tableData.push({
        id: i + 1,
        name: summary[i][0],
        pool_Address: summary[i][1],
        sponsors_count: summary[i][2],
        total_sponsor_amount: summary[i][3],
        total_giveback_amount: summary[i][4],
      });
    }

    // 選取要插入表格的容器元素
    var tableContainer = document.getElementById("table-container");

    // 建立表格元素
    var table = document.createElement("table");

    // 建立表頭
    var thead = document.createElement("thead");
    var headerRow = document.createElement("tr");
    for (var key in tableData[0]) {
      var th = document.createElement("th");
      th.textContent = key;
      headerRow.appendChild(th);
    }
    thead.appendChild(headerRow);
    table.appendChild(thead);

    // 建立表身
    var tbody = document.createElement("tbody");
    tableData.forEach(function (rowData) {
      var row = document.createElement("tr");
      for (var key in rowData) {
        var cell = document.createElement("td");

        if (key == "pool_Address") {
          var link = document.createElement("a");
          link.setAttribute("href", "pool.html?address=" + rowData[key]);
          var linkText = document.createTextNode(rowData[key]);
          link.appendChild(linkText);
          cell.appendChild(link);
          row.appendChild(cell);
        } else {
          var p = document.createElement("p");
          var pText = document.createTextNode(rowData[key]);
          p.appendChild(pText);
          cell.appendChild(p);
          row.appendChild(cell);
        }
      }
      tbody.appendChild(row);
    });
    table.appendChild(tbody);

    // 將表格插入容器元素
    tableContainer.appendChild(table);
  } else {
    fundButton.innerHTML = "Please install MetaMask";
  }
}

async function createProject() {
  const tokenName = document.getElementById("tokenName").value;
  const tokenSymbol = document.getElementById("tokenSymbol").value;
  const sponsoredAddress = document.getElementById("sponsoredAddress").value;
  const sponsoredName = document.getElementById("sponsoredName").value;
  const sponsoredUrl = document.getElementById("sponsoredUrl").value;

  console.log(`tokenName with ${tokenName}...`);
  console.log(`tokenSymbol with ${tokenSymbol}...`);
  console.log(`sponsoredAddress with ${sponsoredAddress}...`);
  console.log(`sponsoredName with ${sponsoredName}...`);
  console.log(`sponsoredUrl with ${sponsoredUrl}...`);

  if (typeof window.ethereum !== "undefined") {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(factoryAddress, factoryAbi, signer);

    try {
      const accounts = await ethereum.request({ method: "eth_accounts" });
      console.log(accounts);

      const balance = await provider.getBalance(accounts[0]);
      console.log(ethers.utils.formatEther(balance));

      const transactionResponse = await contract.createProject(
        tokenName,
        tokenSymbol,
        sponsoredAddress,
        sponsoredName,
        sponsoredUrl
      );
      await listenForTransactionMine(transactionResponse, provider);

      contract.once("ProjectCreated", (from, pool) => {
        console.log(`${from} -> ${pool}`);
        location.reload();
        window.alert("Project created successfully !!!!!");
      });
    } catch (error) {
      console.log(error);
    }
  } else {
    createButton.innerHTML = "Please install MetaMask";
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

window.onload = async function () {
  await queryProjectList();
};
