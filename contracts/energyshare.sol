// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnergySharing {
  uint private newSellOfferId = 1;
  uint private newBuyOfferId = 1;

  struct SellOffer {
    uint id;
    address payable seller;
    uint minEnergyUnits;
    uint maxEnergyUnits;
    uint minPrice;
    uint bestBuyOfferId;
    uint[] buyOfferIds;
    bool sold;
  }

  struct BuyOffer {
    uint id;
    address payable buyer;
    uint sellOfferId;
    uint numberOfEnergyUnits;
    uint price;
  }

  mapping(uint => SellOffer) private sellOffers;
  mapping(uint => BuyOffer) private buyOffers;
  mapping(address => uint[]) private sellOfferList;
  mapping(address => uint[]) private buyOfferList;

  // make sure the sale offer exists
  modifier sellOfferExists(uint _sellOfferId) {

    require(
      _sellOfferId > 0 && _sellOfferId < newSellOfferId,
      "Sell offer does not exist"
    );
    _;
  }

  function createSellOffer(
    uint _minEnergyUnits,
    uint _maxEnergyUnits,
    uint _minPrice
  ) external {
    require(_minEnergyUnits > 0, "Minimum energy units must be greater than 0");
    require(_maxEnergyUnits >= _minEnergyUnits, "Maximum energy units must be greater than or equal to minimum energy units");
    require(_minPrice > 0, "Minimum price per unit must be greater than 0");

    sellOffers[newSellOfferId] = SellOffer({
            id: newSellOfferId,
            seller: payable(msg.sender),
            minEnergyUnits: _minEnergyUnits,
            maxEnergyUnits: _maxEnergyUnits,
            minPrice: _minPrice,
            bestBuyOfferId: 0, // Initialize as 0
            buyOfferIds: new uint[](0), // Initialize as an empty array
            sold: false
        });

        // Add the sell offer ID to the seller's list
        sellOfferList[msg.sender].push(newSellOfferId);

        newSellOfferId++; // Increment the sell offer ID for the next offer.
  }

  function createBuyOffer(uint _sellOfferId, uint _numberOfEnergyUnits, uint _price) public sellOfferExists(_sellOfferId) {
    SellOffer storage sellOffer = sellOffers[_sellOfferId];

    require(msg.sender != sellOffer.seller, "Buyer cannot be the seller");
    require(_numberOfEnergyUnits > 0, "Number of energy units must be greater than 0");
    require(_price > 0, "Price must be greater than 0");

    // Create a new BuyOffer struct
    uint newBuyOfferId = buyOffers.length;
    BuyOffer memory buyOffer = BuyOffer({
        id: newBuyOfferId,
        buyer: payable(msg.sender),
        sellOfferId: _sellOfferId,
        numberOfEnergyUnits: _numberOfEnergyUnits,
        price: _price
    });

    buyOffers.push(buyOffer);

    // Update the corresponding SellOffer's buyOfferIds and bestBuyOfferId
    sellOffer.buyOfferIds.push(newBuyOfferId);

    if (sellOffer.bestBuyOfferId == 0 || ( _price * _numberOfEnergyUnits < buyOffers[sellOffer.bestBuyOfferId].price * buyOffers[sellOffer.bestBuyOfferId].numberOfEnergyUnits)) {
        sellOffer.bestBuyOfferId = newBuyOfferId;
    }

    // Add the buy offer ID to the buyer's buyOfferList
    buyOfferList[msg.sender].push(newBuyOfferId);
  }


  function completeTransaction(uint _sellOfferId) public sellOfferExists(_sellOfferId) {
    // Retrieve the relevant sell offer
    SellOffer storage sellOffer = sellOffers[_sellOfferId];

    require(!sellOffer.sold, "Sell offer has already been sold");
    require(sellOffer.seller == msg.sender, "Only the seller can complete the transaction");

    // Get the buy offer ID from the bestBuyOfferId
    uint buyOfferId = sellOffer.bestBuyOfferId;

    // Ensure that there is a valid buy offer
    require(buyOfferId > 0, "No valid buy offer found");

    // Retrieve the relevant buy offer
    BuyOffer storage buyOffer = buyOffers[buyOfferId];

    // Check if the number of energy units being purchased is within the valid range
    require(
        buyOffer.numberOfEnergyUnits >= sellOffer.minEnergyUnits && 
        buyOffer.numberOfEnergyUnits <= sellOffer.maxEnergyUnits,
        "Invalid number of energy units"
    );

    // Calculate the total cost of the transaction
    uint totalCost = buyOffer.numberOfEnergyUnits * buyOffer.price;

    // Ensure the contract has sufficient balance to cover the transaction
    require(address(this).balance >= totalCost, "Insufficient contract balance");

    // Transfer the energy units to the buyer
    sellOffer.seller.transfer(buyOffer.numberOfEnergyUnits);

    // Transfer the payment to the seller
    buyOffer.buyer.transfer(totalCost);

    // Mark the sell offer as sold
    sellOffer.sold = true;

    // Remove the completed buy offer from the buyer's buyOfferList
    removeBuyOffer(buyOfferId);
  }

  function removeBuyOffer(uint _buyOfferId) private {
    BuyOffer storage buyOffer = buyOffers[_buyOfferId];
    
    // Find the index of the buy offer in the buyer's buyOfferList
    uint indexToDelete = findIndex(buyOfferList[buyOffer.buyer], _buyOfferId);

    // Ensure the buy offer is found in the list
    require(indexToDelete < buyOfferList[buyOffer.buyer].length, "Buy offer not found in the list");

    // Swap the buy offer to be deleted with the last one and then remove the last element
    uint lastIndex = buyOfferList[buyOffer.buyer].length - 1;
    uint lastBuyOfferId = buyOfferList[buyOffer.buyer][lastIndex];
    
    buyOfferList[buyOffer.buyer][indexToDelete] = lastBuyOfferId;
    buyOfferList[buyOffer.buyer].pop();
  }
  
  function getAllCurrentSellOffers() public view returns (SellOffer[] memory) {
    SellOffer[] memory currentSellOffers = new SellOffer[](sellOffers.length);
    uint currentSellOfferCount = 0;

    for (uint i = 1; i < sellOffers.length; i++) {
        // Skip the first sell offer with ID 0 (non-existent)
        if (!sellOffers[i].sold) {
            currentSellOffers[currentSellOfferCount] = sellOffers[i];
            currentSellOfferCount++;
        }
    }

    // Resize the array to exclude any unused slots
    assembly {
        mstore(currentSellOffers, currentSellOfferCount)
    }

    return currentSellOffers;
  }

  function getUserSellOffers(address _user) public view returns (SellOffer[] memory) {
    uint[] storage userSellOfferIds = sellOfferList[_user];
    SellOffer[] memory userSellOffers = new SellOffer[](userSellOfferIds.length);

    for (uint i = 0; i < userSellOfferIds.length; i++) {
        userSellOffers[i] = sellOffers[userSellOfferIds[i]];
    }

    return userSellOffers;
  }

  function getUserBuyOffers(address _user) public view returns (BuyOffer[] memory) {
    uint[] storage userBuyOfferIds = buyOfferList[_user];
    BuyOffer[] memory userBuyOffers = new BuyOffer[](userBuyOfferIds.length);

    for (uint i = 0; i < userBuyOfferIds.length; i++) {
        userBuyOffers[i] = buyOffers[userBuyOfferIds[i]];
    }

    return userBuyOffers;
  }

}
