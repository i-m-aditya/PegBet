// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../src/Controller.sol";
import "../src/Pegbet.sol";

import "forge-std/Test.sol";
import "solmate/tokens/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract PegbetTest is Test, ERC1155Holder {
    Controller public controller;
    Pegbet public pegbet;

    VaultFactory public vaultFactory;

    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address user1 = 0xBB7a9449997c263a5f137Ca53e2Cd0a7f359979f;
    address user2 = 0x634f03509A3b98a49a1c8fE07b1089952C134f8A;

    function setUp() public {
        vaultFactory = new VaultFactory();
        controller = new Controller(address(vaultFactory));
        pegbet = new Pegbet("Pegbet", "pegbet", 18);
    }

    function testVaultCreation() public {
        pegbet.mint(address(this), 100 ether);

        pegbet.mint(address(user1), 100 ether);
        pegbet.mint(address(user2), 100 ether);

        assert(pegbet.balanceOf(address(this)) == 100 ether);

        uint256 startDate = 1691433528;
        uint256 endDate = 1691433528 + 7 days;

        uint256 marketId = vaultFactory.createNewMarket(
            pegbet,
            "PGB-frax-998-epoch",
            "pgb-frax-998-epoch",
            address(0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8),
            998,
            1691433528,
            1691433528 + 7 days
        );

        address payable[] memory vaultAddresses = vaultFactory
            .getVaultsForMaketId(marketId);

        Vault riskVault = Vault(vaultAddresses[0]);
        Vault premiumVault = Vault(vaultAddresses[1]);

        emit log_named_string("vaultAddress risk ", riskVault.name());
        emit log_named_string("vaultAddress premium ", premiumVault.name());

        // vm.prank(user1);

        vm.warp(startDate + 1 days);
        vm.prank(user1);
        ERC20(address(pegbet)).approve(address(riskVault), 1 ether);
        riskVault.deposit(1 ether, endDate, user1);

        vm.prank(user2);
        ERC20(address(pegbet)).approve(address(premiumVault), 1 ether);
        premiumVault.deposit(1 ether, endDate, user2);

        assert(riskVault.balanceOf(user1, endDate) == 1 ether);
        assert(premiumVault.balanceOf(user2, endDate) == 1 ether);

        uint256 fraxLatestPrice = controller.getLatestPrice(
            0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8
        );

        emit log_named_uint("fraxLatestPrice", fraxLatestPrice);

        emit log_named_address("vault factory address", address(vaultFactory));
        emit log_named_address(
            "controller vault factory",
            controller.getVaultFactoryAddress()
        );

        controller.triggerDepeg(marketId);

        assert(riskVault.balanceOf(user1, endDate) == 0);
    }

    // function testHuntForAirdrop() public {
    //     uint256 usdcBalance = ERC20(USDC).balanceOf(user1);
    //     emit log_named_uint("USDC balance", usdcBalance);
    //     uint256 amount = 100 * 10 ** 6;
    //     emit log_named_uint("amount", amount);
    //     vm.startPrank(user1);

    //     assert(ERC20(USDC).approve(user2, amount));
    //     uint256 allowance = ERC20(USDC).allowance(user1, user2);
    //     emit log_named_uint("allowance", allowance);

    //     msgSenderTest.msgSender(user1);

    //     ERC20(USDC).transfer(user2, amount);

    //     assert(ERC20(USDC).balanceOf(user2) > amount);

    //     // airdrop.hunt_for_airdrop{value: 2 ether}( address(0x4E53051c6Bd7dA2Ad2aa22430AD8543431007D23));
    //     // emit log_string("Post");

    //     vm.stopPrank();
    //     assert(true);
    // }

    // function testSftWithUser() public {
    //     uint256 amount = 100 * 10 ** 6;
    //     vm.startPrank(user1);

    //     ERC20(USDC).approve(address(sft), amount);

    //     uint256 allowance = ERC20(USDC).allowance(user1, address(sft));
    //     emit log_named_uint("allowance", allowance);

    //     msgSenderTest.msgSender(user1);

    //     sft.deposit(user1, 1, amount);

    //     assert(ERC1155(address(sft)).balanceOf(user1, 1) == amount);

    //     sft.withdraw(user1, 1, amount);

    //     assert(ERC1155(address(sft)).balanceOf(user1, 1) == 0);

    //     vm.stopPrank();
    // }

    // function testSftWithContract() public {
    //     uint256 amount = 100 * 10 ** 6;
    //     vm.startPrank(user1);

    //     ERC20(USDC).approve(address(this), amount);
    //     ERC20(USDC).transfer(address(this), amount);
    //     msgSenderTest.msgSender(user1);
    //     vm.stopPrank();

    //     ERC20(USDC).approve(address(sft), amount);

    //     // test

    //     emit log_string("Pre call");

    //     sft.deposit(address(this), 1, amount);

    //     assert(ERC1155(address(sft)).balanceOf(address(this), 1) == amount);

    //     // sft.withdraw(user1, 1, amount);

    //     // assert(ERC1155(address(sft)).balanceOf(user1, 1) == 0);

    //     // vm.stopPrank();
    // }

    // function testController() public {
    //     address oracleAddy = 0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7;

    //     uint256 assetPrice = controller.getLatestPrice(oracleAddy);

    //     emit log_named_uint("assetPrice", assetPrice);
    // }

    receive() external payable {}
}
