pragma solidity ^0.8.0;

import "./ERC20Contract.sol";
import "./ERC721Contract.sol";

contract Auction {
    uint256 internal nonce;
    uint256 internal numberOfProduct = 0;

    mapping(uint256 => bool) private _containedTokenList;
    mapping(uint256 => uint256) private _estimatedValue; // 감정가
    mapping(uint256 => uint256) private _bestOffer; // 최고 제시액
    mapping(uint256 => uint256) private _timeLimit;
    mapping(uint256 => address) private _recentBidder;
    mapping(uint256 => ERC721Contract) private _sellerContract;
    mapping(uint256 => ERC20Contract) private _buyerContract;

    function _setEstimatedValue(address senderAddress) private returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, senderAddress, nonce))) % 100 + 1; // 1 to 100
        nonce++;
        return random;
    }

    function _checkNewTokenId(uint256 tokenId) private view returns (bool) {
        return _containedTokenList[tokenId];
    }

    function registerNFT(uint256 tokenId, address sellerContractAddress) public {
        require(!(_checkNewTokenId(tokenId)), "This token ID is already used");
        require(ERC721Contract(sellerContractAddress).ownerOf(tokenId) == msg.sender &&
                ERC721Contract(sellerContractAddress).getApproved(tokenId) == address(this),
                "[Auction] alert >> Authentication error"
        );

        uint256 estimatedValue = _setEstimatedValue(msg.sender);
        _estimatedValue[tokenId] = estimatedValue;

        numberOfProduct++;
        _containedTokenList[tokenId] = true;
        _sellerContract[tokenId] = ERC721Contract(sellerContractAddress);
        _bestOffer[tokenId] = 0;
        _timeLimit[tokenId] = block.timestamp + 60 seconds;
    }

    function getEstimatedValue(uint256 tokenId) public view returns (uint256) {
        return _estimatedValue[tokenId];
    }

    function getBestOffer(uint256 tokenId) public view returns (uint256) {
        return _bestOffer[tokenId];
    }

    function getNumberOfProduct() public view returns (uint256) {
        return numberOfProduct;
    }

    function getTimeLeft(uint256 tokenId) public view returns (int256) {
        int256 _timeLeft = int256(_timeLimit[tokenId]) - int256(block.timestamp);
        if(_timeLeft > 0) {
            return _timeLeft;
        } else {
            return 0;
        }
    }

    function bidding(uint256 tokenId, uint256 price, address buyerContractAddress) public {
        if( (getTimeLeft(tokenId) == 0) && (_bestOffer[tokenId] != 0) ) {       
            _transaction(tokenId, _recentBidder[tokenId]);
            require(false, "!This product has been sold!");
        }

        require(getTimeLeft(tokenId) > 0, "There is no time left for bidding.");
        require(price > _bestOffer[tokenId] && price > _estimatedValue[tokenId], "You should offer higher price.");

        _recentBidder[tokenId] = msg.sender;
        _buyerContract[tokenId] = ERC20Contract(buyerContractAddress);
        _bestOffer[tokenId] = price;
        _timeLimit[tokenId] += 5 seconds;
    }

    function _transaction(uint256 tokenId, address _buyerAddress) private {
        address _seller = _sellerContract[tokenId].ownerOf(tokenId);
        _buyerContract[tokenId].transferFrom(_buyerAddress, _seller, _bestOffer[tokenId]);
        _sellerContract[tokenId].transferFrom(_seller, _buyerAddress, tokenId);
        numberOfProduct--;
    }
}