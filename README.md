# Safe delegated ERC721 Proxy contract documentation

This repository contains the Solidity smart contract code for the SafeDelegatedERC721Proxy contract, which provides a secure and flexible way to manage allowances and permissions for transferring and selling ERC721 tokens on behalf of their owners. The contract interfaces with the ERC721 standard and offers functions to set allowances, check permissions, and execute safe transfers and sales of ERC721 tokens.

It was written to be the interface between a Telegram bot and a Safe smart contract wallet, however the code is completely modular and can be used for any combination of consumers and wallets.

## Overview

The SafeDelegatedERC721Proxy contract keeps track of permissions granted between an ERC721 NFT owner and another contract. It can be used to set fine grained permissions based on certain constraints. It introduces the concept of allowances, where an owner can grant specific permissions to another address to sell or transfer their ERC721 tokens and under what conditions. The contract ensures that these operations are performed securely, verifying the permissions and handling the transfer of tokens and funds accordingly.

### Interfaces

#### ERC721 Interface
This interface defines the standard functions for transferring ERC721 tokens.

```
interface ERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}
```

#### SafeDelegatedERC721ProxyInterface
This interface specifies the functions that the SafeDelegatedERC721Proxy contract implements.

```
interface SafeDelegatedERC721ProxyInterface {
    function canSellNFT(address owner, address nft, uint256 tokenId, address spender) external view returns (bool, uint256);
    function canTransferNFT(address owner, address nft, uint256 tokenId, address spender) external view returns (bool);
    function sellNFT(address owner, address nft, uint256 tokenId, address destination) external payable;
    function transferNFT(address owner, address nft, uint256 tokenId, address destination) external;
    function setAllowance(
        address nft,
        uint256 tokenId,
        bool canBeSold,
        uint256 minPrice,
        address destination,
        bool canBeTransferred
    ) external;
}
```

### Contract Functions

#### generateAllowanceKey

```
function generateAllowanceKey(address owner, address nft, uint256 tokenId, address spender) internal pure returns (bytes32)
```

Generates a unique key based on the provided parameters. This key is used to store and retrieve allowance information.

#### canSellNFT

```
function canSellNFT(address owner, address nft, uint256 tokenId, address spender) external view returns (bool, uint256)
```

Checks if the given spender has permission to sell an ERC721 token on behalf of the owner. Returns a boolean indicating the permission status and the minimum price required for the sale.

#### canTransferNFT

```
function canTransferNFT(address owner, address nft, uint256 tokenId, address spender) external view returns (bool)
```

Checks if the given spender has permission to transfer an ERC721 token on behalf of the owner. Returns a boolean indicating the permission status.

#### sellNFT

```
function sellNFT(address owner, address nft, uint256 tokenId, address destination) external payable
```

Allows the spender to sell an ERC721 token on behalf of the owner. Verifies permissions, minimum price, and handles the transfer of tokens and funds.

#### transferNFT

```
function transferNFT(address owner, address nft, uint256 tokenId, address destination) external
```

Allows the spender to transfer an ERC721 token on behalf of the owner. Verifies permissions and handles the secure transfer of the token.

#### setAllowance

```
function setAllowance(
    address nft,
    uint256 tokenId,
    bool canBeSold,
    uint256 minPrice,
    address destination,
    bool canBeTransferred
) external
```

Sets an allowance for the specified ERC721 token. The owner can grant or revoke permissions for selling and transferring, along with associated parameters like minimum price and destination address.

## Usage

Deploy the SafeDelegatedERC721Proxy contract to the Ethereum network.

Interact with the contract's functions through a compatible user interface or by directly calling the functions using Ethereum transactions.

## Deployments

* goerli https://goerli.etherscan.io/address/0x2e0092bee1ff5902278d64d4e760920c6fd10974#code
* Optimism goerli https://goerli-optimism.etherscan.io/address/0xb9000feb347ab0b180f498f06939834dd7886f94#code

## License
This contract is licensed under the MIT License. See the LICENSE file for details.
