pragma solidity ^0.8.0;

import "./ERC20Contract.sol";
import "./ERC721Contract.sol";

contract Auction {
    ERC20Contract private _erc20;
    ERC721Contract private _erc721;

    constructor(address erc20, address erc721) {
        _erc20 = ERC20Contract(erc20);
        _erc721 = ERC721Contract(erc721);
    }

    struct Product {
        uint256 tokenId;
        uint256 estimatedValue;
    }

    Product[] public products;

    uint256 internal numberOfNFT;
    uint256 internal nonce;
    uint256 internal numberOfProduct;

    mapping(uint256 => uint256) private _estimatedValue; // 감정가
    mapping(uint256 => uint256) private _productPrice; // 최종 낙찰 가격
    mapping(uint256 => uint256) private _bestOffer; // 최고 제시액
    mapping(uint256 => uint256) private _timeLimit;
    mapping(uint256 => address) private _recentBuyer;

    function _setEstimatedValue(address senderAddress) private returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, senderAddress, nonce))) % 100 + 1; // 1 to 100
        nonce++;
        return random;
    }

    function registerNFT(uint256 tokenId) public {
        require(_erc721.ownerOf(tokenId) == msg.sender && 
                _erc721.getApproved(tokenId) == address(this),
                "[Auction] alert >> Authentication error"   
        );

        uint256 estimatedValue = _setEstimatedValue(msg.sender);
        _estimatedValue[tokenId] = estimatedValue;

        products.push(Product(tokenId, _estimatedValue[tokenId]));

        numberOfProduct++;
        _timeLimit[tokenId] = block.timestamp + 10 seconds;
    }

    function getEstimatedValue(uint256 tokenId) public view returns (uint256) {
        return _estimatedValue[tokenId];
    }

    function getBestOffer(uint256 tokenId) public view returns (uint256) {
        return _bestOffer[tokenId];
    }

    function getAllProductInformation() public view returns (string memory) {
        string memory listOfProducts;
        for(uint i = 0; i <= numberOfProduct; i++) {
            listOfProducts = string(abi.encodePacked(products[i].tokenId, products[i].estimatedValue, "\n"));
        }
        return listOfProducts;
    }

    function _auctionSuccess(uint256 tokenId) private {
        address _seller = _erc721.ownerOf(tokenId);
        _erc721.transferFrom(_seller, _recentBuyer[tokenId], tokenId);
    }

    function bidding(uint256 tokenId, uint256 price) public {
        if(_timeLimit[tokenId] <= block.timestamp) {
            _auctionSuccess(tokenId);
        }
        require(_timeLimit[tokenId] <= block.timestamp, "There is no time left for bidding.");
        require(price > _bestOffer[tokenId], "You should offer higher price.");
        address _seller = _erc721.ownerOf(tokenId);
        _erc20.transferFrom(msg.sender, _seller, price);
        if(_bestOffer[tokenId] > 0) {
            _returnMoney(tokenId);
        }
        _recentBuyer[tokenId] = msg.sender;
        _bestOffer[tokenId] = price;
        _timeLimit[tokenId] = block.timestamp + 5 seconds;
    }

    function _returnMoney(uint256 tokenId) private {
        address _seller = _erc721.ownerOf(tokenId);
        _erc20.transferFrom(_seller, _recentBuyer[tokenId], _bestOffer[tokenId]);
    }


}