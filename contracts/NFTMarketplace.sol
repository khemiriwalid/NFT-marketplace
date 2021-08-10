// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC1155, Ownable{  

    enum DROP_TYPE { 
        UNIQUE_PRODUCT_Fixed_PRICE_DROP,
        INVENTORIED_PRODUCT_FIXED_PRICE_DROP
    }

    enum DROP_STATE{
        OPENED,
        CLOSED
    }

    enum PAYMENT_TYPE{
        ETHER,
        USDT
    }

    struct Drop {
        DROP_TYPE dropType;
        DROP_STATE dropState;
        uint256 price;
        //string collectionName;
    }

    uint256 private nextDropID = 1;

    mapping(uint256 => Drop) drops;

    struct TokenDetail{
        uint256 totalSupply;
        uint256 dropPrice;
        string collectionName;
    }

    mapping(uint256 => TokenDetail) tokenDetails;

    struct Collection {
        address user;
        uint256 dropIndex;
    }
                    
    mapping(string => Collection ) collections;
    
    mapping(address => bool) allowedUsersTokenCreation; 
    mapping(address => bool) allowedUsersDropCreation; 
    mapping(address => bool) allowedUsersCollectionCreation; 
    

    constructor() public ERC1155("https://HinataMarketplace/api/item/{id}.json") {
    }

    function mintToken(uint256 _totalSupply, uint256 _tokenId, address _user, uint256 _dropPrice) external {
        require(allowedUsersTokenCreation[_msgSender()] == true, "User not allowed to mint tokens");
        require(_totalSupply > 0, "Total supply must be greater than 0");
        require(tokenDetails[_tokenId].totalSupply == 0, "Id token already exists");
        TokenDetail memory tokenDetail;
        tokenDetail.totalSupply = _totalSupply;
        tokenDetail.dropPrice = _dropPrice;
        _mint(_user, _tokenId , _totalSupply, "");
    }

    function createDrop(DROP_TYPE _dropType, uint256 _price, string memory _collectionName) external {
        require(allowedUsersDropCreation[_msgSender()] == true, "User not allowed to create drops");
        require(collections[_collectionName].dropIndex == 0, "The collection is already used by another drop");
        Drop memory drop = Drop(_dropType, DROP_STATE.OPENED, _price);
        uint256 dropId = nextDropID;
        drops[dropId] = drop;
        collections[_collectionName].dropIndex = dropId;
        _incrementDropId();    
    }

    function createCollection(string memory _collectionName, address _user, uint256[] memory _tokens) external{
        require(allowedUsersCollectionCreation[_msgSender()] == true, "User not allowed to create collections");
        require(collections[_collectionName].user == address(0), "The collection name is already exists");
        Collection memory collection;
        collection.user = _user;
        collections[_collectionName] = collection;
        for(uint256 i=0; i<_tokens.length; i++){
            require(tokenDetails[_tokens[i]].totalSupply > 0, "A token is not minted");
            require(compareStrings(tokenDetails[_tokens[i]].collectionName, ""), "A token is already added to another collection");
            tokenDetails[_tokens[i]].collectionName = _collectionName;
        }
    }

    function buyUniqueProductFixedPriceByEther(uint256 _tokenId) external payable{
        require(msg.value >= tokenDetails[_tokenId].dropPrice , "");
        string memory collectionName = tokenDetails[_tokenId].collectionName;
        Drop memory drop = drops[collections[collectionName].dropIndex];
        require(drop.state == DROP_STATE.OPENED, "");
    }

    function buyUniqueProductFixedPriceByUSDT() external{
        
    }

    function addallowedUserTokenCreation(address _user) external onlyOwner {
        allowedUsersTokenCreation[_user] = true;
    }

    function addallowedUserDropCreation(address _user) external onlyOwner {
        allowedUsersDropCreation[_user] = true;
    }

    function addallowedUserCollectionCreation(address _user) external onlyOwner {
        allowedUsersCollectionCreation[_user] = true;
    }

    function _incrementDropId() internal  {
        nextDropID++;
    }

    function compareStrings(string memory s1, string memory s2) internal pure returns (bool) {
        if(bytes(s1).length != bytes(s2).length) {
            return false;
        } else {
            return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
        }
    }

}
