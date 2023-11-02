// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract LendingAndBorrowing is IERC721Receiver {

    // For simplicity users can only lend eth
    mapping(address => uint) ethBalance;
    // For simplicity users can only borrow eth
    mapping(address => uint) debt;
    // For simplicity only ERC-721 will be accepeted as collateral
    mapping(address => mapping(uint => address)) nftOwners;
    mapping(address => uint) borrowCapacity;

    constructor() {}

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // For simplicity everytime the user lends he will gain 5% of the lended amount as reward
    function lend() public payable {
        uint senderBalance = ethBalance[msg.sender];
        require(senderBalance + msg.value > senderBalance, "Overflow");
        senderBalance += msg.value;

        require(msg.value * 5 > msg.value, "Overflow");
        uint reward = msg.value * 5 / 100;

        require(senderBalance + reward > senderBalance, "Overflow");
        senderBalance += reward;

        ethBalance[msg.sender] = senderBalance;
    }

    // For simplicity everytime the user borrows he will increase his debt by 105% of the amount borrowed
    function borrow(uint amount) public {
        uint senderDebt = debt[msg.sender];
        require(borrowCapacity[msg.sender] - senderDebt > amount, "Not enough collateral");

        require(senderDebt + amount > senderDebt, "Overflow");
        senderDebt += amount;

        require(amount * 5 > amount, "Overflow");
        uint debtIncrease = amount * 5 / 100;

        require(senderDebt + debtIncrease > senderDebt, "Overflow");
        senderDebt += debtIncrease;

        debt[msg.sender] = senderDebt;
        payable(msg.sender).transfer(amount);
    }

    function wihtdraw(uint amount) public {
        uint senderBalance = ethBalance[msg.sender];
        require(senderBalance >= amount, "Not enough balance");

        require(senderBalance - amount < senderBalance, "Overflow");
        ethBalance[msg.sender] -= amount;

        payable(msg.sender).transfer(amount);
    }

    function repay() public payable {
        uint senderDebt = debt[msg.sender];
        require(msg.value <= senderDebt, "Too much value being sent");

        require(senderDebt - msg.value < senderDebt, "Overflow");
        senderDebt -= msg.value;

        debt[msg.sender] = senderDebt;
    }

    // For simplicity each NFT will increase user's borrow capacity by 1e18
    function deposit(address nftAddress, uint tokenId) public {
        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        nftOwners[nftAddress][tokenId] = msg.sender;

        uint senderBorrowCapacity = borrowCapacity[msg.sender];
        require(senderBorrowCapacity + 10 ** 18 > senderBorrowCapacity, "Overflow");
        borrowCapacity[msg.sender] += 10 ** 18;
    }

    function withdrawCollateral(address nftAddress, uint tokenId) public {
        uint senderDebt = debt[msg.sender];
        uint senderBorrowCapacity = borrowCapacity[msg.sender];
        require(senderBorrowCapacity - senderDebt >= 10 ** 18, "Debt must be paid before collateral withdraw");

        require(senderBorrowCapacity - 10 ** 18 < senderBorrowCapacity, "Overflow");
        borrowCapacity[msg.sender] -= 10 ** 18;

        require(nftOwners[nftAddress][tokenId] == msg.sender, "Sender isn't NFT owner");
        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        nftOwners[nftAddress][tokenId] = address(0);
    }

    function isCollateralized(address nftAddress, uint tokenId) public view returns(bool) { return nftOwners[nftAddress][tokenId] == msg.sender; }
    function myBalance() public view returns(uint) { return ethBalance[msg.sender]; }
    function myDebt() public view returns(uint) { return debt[msg.sender]; }
    function myBorrowCapacity() public view returns(uint) { return borrowCapacity[msg.sender]; }
}