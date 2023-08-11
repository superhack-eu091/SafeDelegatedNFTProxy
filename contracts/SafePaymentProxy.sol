// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol
interface IERC721 {
     /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
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
        bool completed;
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
        allowances[key] = PurchaseInfo({initiated:false, completed:false, maxPrice:amount});
    }

    function buyNFT(address nft, uint256 tokenId, uint256 amount, address payable seller) public payable {
        bytes32 key = generateAllowanceKey(nft, tokenId);
        require(amount <= allowances[key].maxPrice);
        // Protect against re-entrancy
        require(!allowances[key].initiated, "Already in progress");

        allowances[key].initiated = true;
        // Send funds which should trigger the send of the NFT in the same call stack
        transferEtherFromGnosisSafe(seller, amount);

        IERC721(nft).transferFrom(address(this), owner, tokenId);

        delete allowances[key];

        // Resulting in the NFT now belonging to the user
        require(allowances[key].completed, "Didn't receive NFT");
    }

    function transferEtherFromGnosisSafe(address payable _to, uint256 _amount) public {
        bytes memory data;  // Optional data for the transaction
        //uint8 operation = 0;  // 0 = CALL, 1 = DELEGATECALL, 2 = CREATE
        Enum.Operation op = Enum.Operation.DelegateCall;

        (bool success) = gnosisSafeInstance.execTransactionFromModule(
            _to,
            _amount,
            data,
            op
        );

        require(success, "Transfer from Gnosis Safe failed");
    }

    function onERC721Received(address operator, address, uint256 tokenId, bytes calldata) external returns (bytes4) {
        // TODO confirm operator is the NFT contract
        bytes32 key = generateAllowanceKey(operator, tokenId);
        // Should be waiting to receive NFT that we've paid for
        require(allowances[key].initiated, "Transfer not expected");
        allowances[key].completed = true;
        return IERC721Receiver.onERC721Received.selector;
    }

}
