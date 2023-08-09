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
        vaultFactory.setController(address(controller));
    }

    function testExpireEpochWithDepeg() public {
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
            99900000,
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
        ERC20(address(pegbet)).approve(address(riskVault), 2 ether);
        riskVault.deposit(2 ether, endDate, user1);

        vm.prank(user2);
        ERC20(address(pegbet)).approve(address(premiumVault), 1 ether);
        premiumVault.deposit(1 ether, endDate, user2);

        emit log_named_uint(
            "pre risk vault balance",
            pegbet.balanceOf(address(riskVault))
        );
        emit log_named_uint(
            "pre premium vault balance",
            pegbet.balanceOf(address(premiumVault))
        );

        uint256 fraxLatestPrice = controller.getLatestPrice(
            0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8
        );

        emit log_named_uint("fraxLatestPrice", fraxLatestPrice);
        int256 sp = riskVault.strikePrice();

        emit log_named_int("strikePrice", sp);

        riskVault.setVaultFinalTVL(endDate);
        premiumVault.setVaultFinalTVL(endDate);

        controller.expireEpochWithDepeg(marketId, endDate);

        emit log_named_uint(
            "post risk vault balance",
            pegbet.balanceOf(address(riskVault))
        );
        emit log_named_uint(
            "post premium vault balance",
            pegbet.balanceOf(address(premiumVault))
        );

        uint256 fraxPgbTokensOfUser1 = riskVault.balanceOf(user1, endDate);
        uint256 fraxPgbTokensOfUser2 = premiumVault.balanceOf(user2, endDate);

        vm.warp(endDate + 1 days);

        vm.prank(user1);
        riskVault.withdraw(endDate, fraxPgbTokensOfUser1, user1);

        vm.prank(user2);
        premiumVault.withdraw(endDate, fraxPgbTokensOfUser2, user2);

        emit log_named_uint(
            "post user1 balance",
            ERC20(address(pegbet)).balanceOf(user1)
        );

        emit log_named_uint(
            "post user2 balance",
            ERC20(address(pegbet)).balanceOf(user2)
        );
    }

    function testExpireEpochWithoutDepeg() public {
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
            99800000,
            1691433528,
            1691433528 + 7 days
        );

        address payable[] memory vaultAddresses = vaultFactory
            .getVaultsForMaketId(marketId);

        Vault riskVault = Vault(vaultAddresses[0]);
        Vault premiumVault = Vault(vaultAddresses[1]);

        emit log_named_string("vaultAddress risk ", riskVault.name());
        emit log_named_string("vaultAddress premium ", premiumVault.name());

        emit log_named_uint(
            "pre user1 balance",
            ERC20(address(pegbet)).balanceOf(user1)
        );

        emit log_named_uint(
            "pre user2 balance",
            ERC20(address(pegbet)).balanceOf(user2)
        );

        vm.warp(startDate + 1 days);
        vm.prank(user1);
        ERC20(address(pegbet)).approve(address(riskVault), 2 ether);
        riskVault.deposit(2 ether, endDate, user1);

        vm.prank(user2);
        ERC20(address(pegbet)).approve(address(premiumVault), 1 ether);
        premiumVault.deposit(1 ether, endDate, user2);

        uint256 fraxLatestPrice = controller.getLatestPrice(
            0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8
        );

        emit log_named_uint("fraxLatestPrice", fraxLatestPrice);
        int256 sp = riskVault.strikePrice();

        emit log_named_int("strikePrice", sp);

        riskVault.setVaultFinalTVL(endDate);
        premiumVault.setVaultFinalTVL(endDate);

        controller.expireEpochWithoutDepeg(marketId, endDate);

        emit log_named_uint(
            "post risk vault balance",
            pegbet.balanceOf(address(riskVault))
        );
        emit log_named_uint(
            "post premium vault balance",
            pegbet.balanceOf(address(premiumVault))
        );

        uint256 fraxPgbTokensOfUser1 = riskVault.balanceOf(user1, endDate);
        uint256 fraxPgbTokensOfUser2 = premiumVault.balanceOf(user2, endDate);

        vm.warp(endDate + 1 days);

        vm.prank(user1);
        riskVault.withdraw(endDate, fraxPgbTokensOfUser1, user1);

        vm.prank(user2);
        premiumVault.withdraw(endDate, fraxPgbTokensOfUser2, user2);

        emit log_named_uint(
            "post user1 balance",
            ERC20(address(pegbet)).balanceOf(user1)
        );

        emit log_named_uint(
            "post user2 balance",
            ERC20(address(pegbet)).balanceOf(user2)
        );
    }

    function testExpireEpochWithSingleSideLiquidity() public {
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
            99800000,
            1691433528,
            1691433528 + 7 days
        );

        address payable[] memory vaultAddresses = vaultFactory
            .getVaultsForMaketId(marketId);

        Vault riskVault = Vault(vaultAddresses[0]);
        Vault premiumVault = Vault(vaultAddresses[1]);

        emit log_named_string("vaultAddress risk ", riskVault.name());
        emit log_named_string("vaultAddress premium ", premiumVault.name());

        emit log_named_uint(
            "pre user1 balance",
            ERC20(address(pegbet)).balanceOf(user1)
        );

        emit log_named_uint(
            "pre user2 balance",
            ERC20(address(pegbet)).balanceOf(user2)
        );

        vm.warp(startDate + 1 days);
        vm.prank(user1);
        ERC20(address(pegbet)).approve(address(riskVault), 2 ether);
        riskVault.deposit(2 ether, endDate, user1);

        // vm.prank(user2);
        // ERC20(address(pegbet)).approve(address(premiumVault), 1 ether);
        // premiumVault.deposit(1 ether, endDate, user2);

        uint256 fraxLatestPrice = controller.getLatestPrice(
            0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8
        );

        emit log_named_uint("fraxLatestPrice", fraxLatestPrice);
        int256 sp = riskVault.strikePrice();

        emit log_named_int("strikePrice", sp);

        riskVault.setVaultFinalTVL(endDate);
        premiumVault.setVaultFinalTVL(endDate);

        controller.expireEpochWithSingleSideLiquidity(marketId, endDate);

        emit log_named_uint(
            "post risk vault balance",
            pegbet.balanceOf(address(riskVault))
        );
        emit log_named_uint(
            "post premium vault balance",
            pegbet.balanceOf(address(premiumVault))
        );

        uint256 fraxPgbTokensOfUser1 = riskVault.balanceOf(user1, endDate);
        uint256 fraxPgbTokensOfUser2 = premiumVault.balanceOf(user2, endDate);

        vm.warp(endDate + 1 days);

        vm.prank(user1);
        riskVault.withdraw(endDate, fraxPgbTokensOfUser1, user1);

        // vm.prank(user2);
        // premiumVault.withdraw(endDate, fraxPgbTokensOfUser2, user2);

        emit log_named_uint(
            "post user1 balance",
            ERC20(address(pegbet)).balanceOf(user1)
        );

        emit log_named_uint(
            "post user2 balance",
            ERC20(address(pegbet)).balanceOf(user2)
        );
    }

    receive() external payable {}
}
