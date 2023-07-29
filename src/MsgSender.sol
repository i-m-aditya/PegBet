// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MsgSenderTest {
    address public sender;

    event LogAddress(address);

    function msgSender(address user) public {
        emit LogAddress(msg.sender);
        require(user == msg.sender, "Not the sender\n");
    }
}
