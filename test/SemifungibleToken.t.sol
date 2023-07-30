// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../src/MsgSender.sol";
import "../src/SemifungibleToken.sol";

import "forge-std/Test.sol";
import "solmate/tokens/ERC20.sol";

contract SemifungibleTokenTest is Test {
    MsgSenderTest public msgSenderTest;
    SemifungibleToken public sft;

    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address user1 = 0xBB7a9449997c263a5f137Ca53e2Cd0a7f359979f;
    address user2 = 0x634f03509A3b98a49a1c8fE07b1089952C134f8A;

    function setUp() public {
        msgSenderTest = new MsgSenderTest();
        sft = new SemifungibleToken(ERC20(USDC), "SFT", "sft");
    }

    function testHuntForAirdrop() public {
        uint256 usdcBalance = ERC20(USDC).balanceOf(user1);
        emit log_named_uint("USDC balance", usdcBalance);
        uint256 amount = 100 * 10 ** 6;
        emit log_named_uint("amount", amount);
        vm.startPrank(user1);

        assert(ERC20(USDC).approve(user2, amount));
        uint256 allowance = ERC20(USDC).allowance(user1, user2);
        emit log_named_uint("allowance", allowance);

        msgSenderTest.msgSender(user1);

        ERC20(USDC).transfer(user2, amount);

        assert(ERC20(USDC).balanceOf(user2) > amount);

        // airdrop.hunt_for_airdrop{value: 2 ether}( address(0x4E53051c6Bd7dA2Ad2aa22430AD8543431007D23));
        // emit log_string("Post");

        vm.stopPrank();
        assert(true);
    }

    function testSftWithUser() public {
        uint256 amount = 100 * 10 ** 6;
        vm.startPrank(user1);

        ERC20(USDC).approve(address(sft), amount);

        uint256 allowance = ERC20(USDC).allowance(user1, address(sft));
        emit log_named_uint("allowance", allowance);

        msgSenderTest.msgSender(user1);

        sft.deposit(user1, 1, amount);

        assert(ERC1155(address(sft)).balanceOf(user1, 1) == amount);

        sft.withdraw(user1, 1, amount);

        assert(ERC1155(address(sft)).balanceOf(user1, 1) == 0);

        vm.stopPrank();
    }

    // function testSftWithContract() public {
    //     uint256 amount = 100 * 10 ** 6;
    //     vm.startPrank(user1);

    //     ERC20(USDC).approve(address(this), amount);

    //     uint256 allowance = ERC20(USDC).allowance(user1, address(this));
    //     emit log_named_uint("allowance", allowance);

    //     msgSenderTest.msgSender(user1);

    //     sft.deposit(user1, 1, amount);

    //     assert(ERC1155(address(sft)).balanceOf(user1, 1) == amount);

    //     sft.withdraw(user1, 1, amount);

    //     assert(ERC1155(address(sft)).balanceOf(user1, 1) == 0);

    //     vm.stopPrank();
    // }

    receive() external payable {}
}
