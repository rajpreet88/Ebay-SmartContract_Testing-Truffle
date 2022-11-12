// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;

contract Ebay {
    struct Auction {
        uint256 id; // auction id of the product being sold/ or in auction
        address payable seller; //address of the seller
        string productName; // name of the product being sold
        string productDescription; //Description of the product being sold
        uint256 minAmount; //minimum auction amount of the product for bidding/offering
        uint256 bestOfferId; //the id which bids the highest value for the product being sold
        uint256[] offerIds; //to store all the offers ids who are bidding for the product being sold
    }

    struct Offer {
        uint256 offerId; // Offer id from which auction is bid for product
        uint256 auctionId; // for which product the auction is done. one might make multiple auctions
        address payable buyer; //buyer/bidder of the product in auction
        uint256 buyerPrice; //price that the buyer has bid int the product auction
    }

    mapping(uint256 => Auction) private auctions; //mapping array auctions[uint] to a particular Auction struct considering there can me multiple auctions
    mapping(uint256 => Offer) private offers; //mapping array offers[uint] to a particular Offer struct considering there can be multipe offers
    mapping(address => uint256[]) private auctionList; //mapping the address to the auctionList array with each new auction;
    mapping(address => uint256[]) private offerList; //mapping the address to the offerList array with each new offers;

    uint256 private newAuctionId = 1; // first or new auction initialization
    uint256 private newOfferId = 1; // first or new offer initialization

    // address[] bidderAddresses;
    address payable sellerAddress;

    //function to create our auction. calldata is used to make the arguments passed as read only. we cannot write or change values of the arguments passed with calldata
    function createAuction(
        string calldata _productName,
        string calldata _productDescription,
        uint256 _minAmount
    ) external {
        require(_minAmount > 0, "Minimum Amount must be greater than 0");
        uint256[] memory offerIDS = new uint256[](0); //initial offerIds array will be empty during the creation of the auction

        auctions[newAuctionId] = Auction(
            newAuctionId,
            payable(msg.sender),
            _productName,
            _productDescription,
            _minAmount,
            0,
            offerIDS
        );

        sellerAddress = payable(msg.sender);
        auctionList[msg.sender].push(newAuctionId);
        newAuctionId++;
    }

    function createOffer(uint256 _auctionId)
        external
        payable
        auctionExists(_auctionId)
    {
        Auction storage auction = auctions[_auctionId]; //adding auctions[1] to a new Auction Struct variable named auction to point to the same address
        Offer storage bestOffer = offers[auction.bestOfferId];

        require(msg.sender != sellerAddress, "Seller Cannot Bid in Auction");
        // require(offerList.includes(msg.sender)== false);
        require(
            msg.value >= auction.minAmount && msg.value >= bestOffer.buyerPrice,
            "Bidding value should greater than minimum and bestOffer"
        );

        auction.bestOfferId = newOfferId;
        auction.offerIds.push(newOfferId);

        offers[newOfferId] = Offer(
            newOfferId,
            _auctionId,
            payable(msg.sender),
            msg.value
        );
        offerList[msg.sender].push(newOfferId);
        newOfferId++;
    }

    function transactions(uint256 _auctionID)
        external
        payable
        auctionExists(_auctionID)
    {
        // require(
        //     msg.sender == sellerAddress,
        //     "Only the auctioner can transfer the final amount"
        // );
        Auction storage auction = auctions[_auctionID];
        Offer storage bestOffer = offers[auction.bestOfferId];

        for (uint256 i = 0; i < auction.offerIds.length; i++) {
            uint256 offerId = auction.offerIds[i];

            if (offerId != auction.bestOfferId) {
                Offer storage offer = offers[offerId];
                offer.buyer.transfer(offer.buyerPrice); // if the offerid != the bestOfferif then return the payment from the contract address to the offerid's address
            }
        }
        auction.seller.transfer(bestOffer.buyerPrice); // else transfer the bestoffer price from contract to the auctioner's address/seller
    }

    //display all the available auctions
    function getAuctions() external view returns (Auction[] memory) {
        Auction[] memory _auctions = new Auction[](newAuctionId - 1);

        for (uint256 i = 1; i < newAuctionId; i++) {
            _auctions[i - 1] = auctions[i];
        }
        return _auctions;
    }

    //display all available auctions by a particular user
    function getUserAuctions(address _user)
        external
        view
        returns (Auction[] memory)
    {
        uint256[] storage userAuctionIds = auctionList[_user];
        Auction[] memory _auctions = new Auction[](userAuctionIds.length);

        for (uint256 i = 0; i < userAuctionIds.length; i++) {
            uint256 auctionId = userAuctionIds[i];
            _auctions[i] = auctions[auctionId];
        }
        return _auctions;
    }

    //display all available offers by a particular user
    function getUserOffers(address _user)
        external
        view
        returns (Offer[] memory)
    {
        uint256[] storage userOfferIds = offerList[_user];
        Offer[] memory _offers = new Offer[](userOfferIds.length);

        for (uint256 i = 0; i < userOfferIds.length; i++) {
            uint256 offerId = userOfferIds[i];
            _offers[i] = offers[offerId];
        }
        return _offers;
    }

    //precondition to check if auctions exits or not
    modifier auctionExists(uint256 _auctionId) {
        require(
            _auctionId > 0 && _auctionId < newAuctionId,
            "Auction Id does not exist"
        );
        _;
    }
}
