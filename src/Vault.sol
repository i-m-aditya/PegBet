// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./PartialFungibleVault.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract Vault is PartialFungibleVault {
    using FixedPointMathLib for uint256;

    uint256 public strikePrice;
    address public oracle;
    address public controller;

    string public vaultType;

    uint256[] public epochs;

    mapping(uint256 => uint256) preEpochTVL;
    mapping(uint256 => uint256) postEpochTVL;

    // mapping(uint256 => bool) hasEpochStarted;
    mapping(uint256 => bool) hasEpochEnded;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error AddressZero();
    error SenderNotOwner();

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        ERC20 _asset,
        string memory _name, // PGB-MIM-998-epoch#RISK
        string memory _symbol, // pgb-mim
        address _oracle,
        uint256 _strikePrice, // strike price multiplied by 10**8
        address _controller, // unix timestamp of expiry
        string memory _vaultType
    ) PartialFungibleVault(_asset, _name, _symbol) {
        strikePrice = _strikePrice;
        oracle = _oracle;
        controller = _controller;
        vaultType = _vaultType;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyController() {
        require(msg.sender == controller, "Vault: not controller");
        _;
    }

    function createMarketForNewExpiry(uint256 _expiry) public onlyController {
        hasEpochEnded[_expiry] = false;
        epochs.push(_expiry);
    }

    function endEpoch(uint256 _expiry) public onlyController {
        hasEpochEnded[_expiry] = true;
    }

    function deposit(uint256 amount, uint256 id, address receiver) public {
        require(amount > 0, "Vault: amount must be greater than 0");
        require(
            hasEpochEnded[id] == false,
            "Vault: epoch has ended, cannot deposit"
        );
        super.deposit(receiver, id, amount);
    }

    function depositEth(uint256 id, address receiver) public payable {
        require(msg.value > 0, "Vault: amount must be greater than 0");
        require(
            hasEpochEnded[id] == false,
            "Vault: epoch has ended, cannot deposit"
        );
        super.deposit(receiver, id, msg.value);
    }

    function withdraw(
        uint256 amount,
        uint256 id,
        address owner,
        address receiver
    ) public {
        require(amount > 0, "Vault: amount must be greater than 0");
        require(
            hasEpochEnded[id] == true,
            "Vault: epoch has not ended, cannot withdraw"
        );
        if (owner != msg.sender) revert SenderNotOwner();

        _burn(owner, id, amount);
        // transfer receivers earning
    }

    // function withdrawConversion(

    // ) public {
    //     require(amount > 0, "Vault: amount must be greater than 0");
    //     require(
    //         hasEpochEnded[id] == true,
    //         "Vault: epoch has not ended, cannot withdraw"
    //     );
    //     if (owner != msg.sender) revert SenderNotOwner();

    //     _burn(owner, id, amount);
    //     // transfer receivers earning
    // }
}
