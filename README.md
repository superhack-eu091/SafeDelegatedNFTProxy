# Safe delegated ERC721 Proxy contract

This repository contains the Solidity smart contract code for the SafeDelegatedERC721Proxy contract, which provides a secure and flexible way to manage allowances and permissions for transferring and selling ERC721 tokens on behalf of their owners. The contract interfaces with the ERC721 standard and offers functions to set allowances, check permissions, and execute safe transfers and sales of ERC721 tokens.

It was written to be the interface between a Telegram bot and a Safe smart contract wallet, however the code is completely modular and can be used for any combination of consumers and wallets.

## Overview

The SafeDelegatedERC721Proxy contract consists of two main functionalities: buying and selling ERC721 tokens. It leverages the Gnosis Safe executor to execute transactions without the counter-party having access to all the NFTs and tokens in the wallet. 

It does this by maintaining allowances between the buying and selling of NFTs, specifically what NFTs the owner wants to buy (and how much for) as well as what they are prepared to sell, who to and what is the minimum they expect to receive for the NFT. The contract ensures that these operations are performed securely, verifying the permissions and handling the transfer of tokens and funds accordingly.

## Demo

https://github.com/superhack-eu091/SafeDelegatedProxy/assets/21056525/7314e7d5-9a3d-4624-b24c-f98283f6132f

### Buying NFTs

The buying logic allows users to set a maximum amount they are willing to pay for a specific ERC721 token. When a user initiates a purchase, the contract verifies the maximum price set by the user and transfers the specified amount to the seller's address. Simultaneously, the NFT is transferred to the buyer. The contract prevents re-entrancy attacks during the process.

### Selling NFTs

The selling logic enables users to specify whether their ERC721 tokens can be sold and transferred. Sellers can set minimum prices for their tokens if they wish to receive a certain amount before transferring ownership. Transfers and sales are securely executed using the Gnosis Safe executor.

## Logic flow for Telegram bot <> Safe smart contract wallet interactions

Entities:
* Bob prod would-be owner / owner of NFT
* Safe smart contract wallet (SCW)
* Safe delegate - this contract (DEL)
* Telegram bot EOA (TG)
* Market adaptor (MARKET)

### Bob wants to buy an NFT

![image](https://github.com/superhack-eu091/SafeDelegatedProxy/assets/21056525/9f29cfda-b511-467e-919d-b44a7957e8e3)

🏗️ TODO: Describe flow

### Bob wants to sell an NFT

![image](https://github.com/superhack-eu091/SafeDelegatedProxy/assets/21056525/d4d56ecc-cacc-40a4-91a8-d01dcb5bb81f)

🏗️ TODO: Describe flow

* SCW approves DEL to sell an NFT
* SCW calls setAllowance( [nft address and id], canBeSold=true, )

## Deployments

See https://github.com/superhack-eu091/TiGr-Bot/blob/main/README.md#deployed-contracts.

## Usage

The SafeDelegatedERC721Proxy contract provides a set of functions to interact with the buying and selling functionalities:

### Buying

#### setMaxAmountToPayForNFT

```
function setMaxAmountToPayForNFT(
    address owner,
    address nft,
    uint256 tokenId,
    uint256 amount,
    address spender) public
```

* *owner* will be the new owner of the NFT (must be a Safe wallet address)
* *nft* contract for ERC721 being bought
* *tokenId* nft index
* *amount* maximum amount new owner is willing to pay for NFT
* *spender* Safe wallet address for owner (currently ignored)

Can only be called by *owner* address.

Allows the owner of an NFT to set a maximum amount they are willing to pay for its purchase.

#### getMaxAmountToPayForNFT

```
function getMaxAmountToPayForNFT(
    address owner,
    address nft,
    uint256 tokenId) public view returns (uint256)
```

Returns the max price in wei that this user has allowed a spender to take for a particular NFT. If the function returns 0, it means the user has not allowed this NFT to be bought.

#### buyNFT

```
function buyNFT(
    address owner,
    address nft,
    uint256 tokenId,
    uint256 amount,
    address payable seller) public
```

* *owner* will be the new owner of the NFT (must be a Safe wallet address)
* *nft* contract for ERC721 being bought
* *tokenId* nft index
* *amount* maximum amount new owner is willing to pay for NFT
* *seller* market place contract that processes the purchase (use the Mock Market contract adaptor example)

Initiates the process of buying an NFT from a seller, considering the set maximum price. Will transfer funds from Safe wallet from owner, send them to seller and expect the NFT to be sent to the contract in an atomic operation. The function will then forward the NFT to the owner address. If any of these steps fail or the NFT is not sent in return for payment, the entire call reverts.

### Selling

#### setSellAllowance

```
function setSellAllowance(
    address nft,
    uint256 tokenId,
    bool canBeSold,
    uint256 minPrice,
    address destination,
    bool canBeTransferred
) external
```

Sellers can set allowances for their NFTs to be sold, specifying minimum prices and transfer permissions.

Sets an allowance for the specified ERC721 token. The owner can grant or revoke permissions for selling and transferring, along with associated parameters like minimum price and destination address.

#### sellNFT

Allows the spender to sell an ERC721 token on behalf of the owner. Verifies permissions, minimum price, and handles the transfer of tokens and funds.

#### transferNFT

Allows the spender to transfer an ERC721 token on behalf of the owner. Verifies permissions and handles the secure transfer of the token.

#### canSellNFT and canTransferNFT

Query functions to check if an NFT can be sold or transferred.

Checks if the given spender has permission to sell / transfer an ERC721 token on behalf of the owner. Returns a boolean indicating the permission status and the minimum price required for the sale for canSellNFT and a boolean indicating the permission status for canTransferNFT

## License
This contract is licensed under the MIT License. See the LICENSE file for details.
