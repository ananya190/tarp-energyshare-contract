// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnergySharing {

    struct EnergyTransaction {
        address payable seller;
        address payable buyer;
        uint256 energyAmount;
        uint256 price;
        bool completed;
    }

    EnergyTransaction[] public transactions;
    mapping(uint256 => bool) public validTransactionIds; // Mapping to store valid transaction IDs

    event EnergyTransactionCreated(uint256 transactionId, address seller, address buyer, uint256 energyAmount, uint256 price);
    event EnergyTransactionCompleted(uint256 transactionId);

    function createTransaction(address payable _seller, address payable _buyer, uint256 _energyAmount, uint256 _price) public payable {
        require(_seller != address(0), "Invalid seller address");
        require(_buyer != address(0), "Invalid buyer address");
        require(_energyAmount > 0, "Energy amount must be greater than zero");
        require(msg.value == _energyAmount * _price, "Incorrect payment value");

        // Generate a unique transactionId based on factors like timestamp, addresses, and a nonce
        uint256 transactionId = uint256(keccak256(abi.encodePacked(block.timestamp, _seller, _buyer, _energyAmount, _price, transactions.length));

        transactions.push(EnergyTransaction(_seller, _buyer, _energyAmount, _price, false));
        validTransactionIds[transactionId] = true; // Mark the transaction ID as valid

        emit EnergyTransactionCreated(transactionId, _seller, _buyer, _energyAmount, _price);
    }

    function completeTransaction(uint256 _transactionId) public {
        require(validTransactionIds[_transactionId], "Invalid transaction ID"); // Check if the transaction ID is valid
        EnergyTransaction storage transaction = transactions[_transactionId];
        require(msg.sender == transaction.buyer, "Only the buyer can complete the transaction");
        require(!transaction.completed, "Transaction has already been completed");

        // Transfer ETH from the buyer to the seller
        transaction.seller.transfer(transaction.energyAmount * transaction.price);

        transaction.completed = true;

        emit EnergyTransactionCompleted(_transactionId);
    }
}
