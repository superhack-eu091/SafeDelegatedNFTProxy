// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol
interface IERC721 {

    function ownerOf(uint256 _tokenId) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

// from import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// From code sample found
contract Enum {
    enum Operation {
        Call, DelegateCall
    }
}

interface Executor {
    /// @dev Allows a Module to execute a transaction.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);
}

contract TrustLessNFTBuyer is IERC721Receiver {
    address public owner;
    Executor public gnosisSafeInstance;  // Address of the Gnosis Safe instance

    struct PurchaseInfo {
        bool initiated;
        uint256 maxPrice;
    }

    // For a given nft and index, specify the maximum amount that will be paid
    mapping(bytes32 => PurchaseInfo) public allowances;

    constructor(address _gnosisSafeAddress) {
        owner = msg.sender;
        gnosisSafeInstance = Executor(_gnosisSafeAddress);
    }

    function generateAllowanceKey(address nft, uint256 tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(nft, tokenId));
    }

    function getMaxAmountToPayForNFT(address nft, uint256 tokenId) public view returns (uint256) {
        bytes32 key = generateAllowanceKey(nft, tokenId);
        return allowances[key].maxPrice;
    }

    function setMaxAmountToPayForNFT(address nft, uint256 tokenId, uint256 amount) public {
        bytes32 key = generateAllowanceKey(nft, tokenId);
        allowances[key] = PurchaseInfo({initiated:false, maxPrice:amount});
    }

    function buyNFT(address nft, uint256 tokenId, uint256 amount, address payable seller) public payable {
        bytes32 key = generateAllowanceKey(nft, tokenId);
        require(amount <= allowances[key].maxPrice);
        // Protect against re-entrancy
        require(!allowances[key].initiated, "Already in progress");

        allowances[key].initiated = true;

        // It's expected the receiver of the funds sends the NFT in the same transaction
        transferEtherFromGnosisSafe(seller, amount);

        // Resulting in the NFT now belonging to the user
        require(IERC721(nft).ownerOf(tokenId) == address(this), "NFT not transferred");

        delete allowances[key];

        // Now this contract owns the NFT, forward it to the real owner
        IERC721(nft).transferFrom(address(this), owner, tokenId);
    }

    function transferEtherFromGnosisSafe(address payable _to, uint256 _amount) public {
        bytes memory data;  // Optional data for the transaction
        Enum.Operation op = Enum.Operation.DelegateCall;

        // TODO add data for the executor receiver (this contract), NFT address, ID
        (bool success) = gnosisSafeInstance.execTransactionFromModule(
            _to,
            _amount,
            data,
            op
        );

        require(success, "Transfer from Gnosis Safe failed");
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

}
