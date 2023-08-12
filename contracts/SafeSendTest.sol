// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    
contract SafeSendTest {

    function transferEtherFromGnosisSafe(
        Executor payer,
        address payable _to,
        uint256 _amount) public {

        bytes memory data;

        Enum.Operation op = Enum.Operation.DelegateCall;
        (bool success) = payer.execTransactionFromModule(
            _to,
            _amount,
            data,
            op
        );

        require(success, "Transfer from Gnosis Safe failed");
    }

}