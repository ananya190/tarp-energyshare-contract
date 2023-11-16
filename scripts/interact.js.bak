const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;

const { ethers } = require("hardhat");
const contract = require("../artifacts/contracts/energyshare.sol/EnergySharing.json");

// uncomment the line below to see the ABI in the console
// console.log(JSON.stringify(contract.abi));

const alchemyProvider = new ethers.providers.AlchemyProvider(
    (network = "goerli"),
    API_KEY
);

const signer = new ethers.Wallet(PRIVATE_KEY, alchemyProvider);

const contractInstance = new ethers.Contract(
    CONTRACT_ADDRESS,
    contract.abi,
    signer,
)

// function: create a new energy transaction
async function createEnergyTransaction(_seller, _buyer, _energyAmount, _price) {
    try {
        const transaction = await contractInstance.createTransaction(_seller, _buyer, _energyAmount, _price, {
            value: ethers.utils.parseEther((_energyAmount * _price).toString())
        });
        await transaction.wait();
        console.log("Transaction Hash:", transaction.hash);
    } catch (error) {
        console.error("Error:", error);
    }

}// function: complete an energy transaction
async function completeEnergyTransaction(transactionId) {
    try {
        const transaction = await contractInstance.completeTransaction(_transactionId);
        await transaction.wait();
        console.log("Transaction Hash:", transaction.hash);
    } catch (error) {
        console.error("Error:", error);
    }
}

module.exports = {
    createEnergyTransaction,
    completeEnergyTransaction,
};