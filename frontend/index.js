import { ethers } from "./ethers-5.6.esm.min.js";
import {
  factoryAbi,
  delegatorAbi,
  factoryAddress,
  delegatorAddress,
} from "./constants.js";

const connectButton = document.getElementById("connectButton");
const queryButton = document.getElementById("queryListButton");

connectButton.onclick = connect;
queryButton.onclick = queryProjectList;

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
    const number = await contract.projectNumber();
    console.log(number.toNumber());

    var tableData = [];
    for (var i = 0; i < number.toNumber(); i++) {
      const addr = await contract.allProjects(i);
      tableData.push({ id: i, name: addr });
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
        var link = document.createElement("a");
        link.setAttribute("href", "pool.html?address=" + rowData[key]);
        var linkText = document.createTextNode(rowData[key]);
        link.appendChild(linkText);
        cell.appendChild(link);
        row.appendChild(cell);
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

window.onload = async function () {
  await queryProjectList();
};
