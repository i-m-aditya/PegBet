// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./PartialFungibleVault.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract Vault is PartialFungibleVault, ReentrancyGuard {
    using FixedPointMathLib for uint256;

    int256 public strikePrice;
    address public oracle;
    address public controller;

    uint256[] public epochs;

    mapping(uint256 => uint256) public vaultFinalTVL;
    mapping(uint256 => uint256) public vaultClaimabeTVL;

    // mapping(uint256 => bool) hasEpochStarted;
    mapping(uint256 => uint8) epochState;
    mapping(uint256 => bool) isEpochIdValid;

    mapping(uint256 => uint256[]) public epochSpan;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error AddressZero();
    error SenderNotOwner();
    error DepositPeriodEnded();
    error WithdrawPeriodNotStarted();

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        ERC20 _asset,
        string memory _name, // PGB-MIM-998-epoch#RISK
        string memory _symbol, // pgb-mim
        address _oracle,
        int256 _strikePrice, // strike price multiplied by 10**8
        address _controller // unix timestamp of expiry
    ) PartialFungibleVault(_asset, _name, _symbol) {
        strikePrice = _strikePrice;
        oracle = _oracle;
        controller = _controller;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyController() {
        require(msg.sender == controller, "Vault: not controller");
        _;
    }

    function startNewEpoch(uint256 startEpoch, uint256 endEpoch) public {
        epochSpan[endEpoch] = [startEpoch, endEpoch];
        epochState[endEpoch] = 0;
        epochs.push(endEpoch);
        isEpochIdValid[endEpoch] = true;
    }

    function setEpochState(
        uint256 _epochId,
        uint8 state
    ) public onlyController {
        require(isEpochIdValid[_epochId], "Vault: epoch id is not valid");
        epochState[_epochId] = state;
    }

    function deposit(
        uint256 amount,
        uint256 id,
        address receiver
    ) public nonReentrant {
        require(amount > 0, "Vault: amount must be greater than 0");

        if (
            epochSpan[id][0] <= block.timestamp &&
            epochSpan[id][0] + 2 days > block.timestamp
        ) {
            super.deposit(receiver, id, amount);
        } else {
            revert DepositPeriodEnded();
        }
    }

    function depositEth(
        uint256 id,
        address receiver
    ) public payable nonReentrant {
        require(msg.value > 0, "Vault: amount must be greater than 0");
        require(epochState[id] == 0, "Vault: Deposit period over");
        super.deposit(receiver, id, msg.value);
    }

    function withdraw(
        uint256 amount,
        uint256 id,
        address owner,
        address receiver
    ) public {
        require(amount > 0, "Vault: amount must be greater than 0");
        if (owner != msg.sender) revert SenderNotOwner();

        if (block.timestamp < epochSpan[id][1]) {
            revert WithdrawPeriodNotStarted();
        }

        _burn(owner, id, amount);

        uint256 eligibleAmount = withdrawConversion(id, amount);
        asset.transfer(receiver, eligibleAmount);
    }

    function withdrawConversion(
        uint256 epochId,
        uint256 amount
    ) public view returns (uint256 eligibleWithdraw) {
        eligibleWithdraw = amount.mulDivUp(
            vaultFinalTVL[epochId],
            vaultClaimabeTVL[epochId]
        );
    }

    function setVaultClaimableTVL(
        uint256 epochId,
        uint256 _vaultClaimableTVL
    ) public onlyController {
        require(isEpochIdValid[epochId], "Vault: epoch id is not valid");
        vaultClaimabeTVL[epochId] = _vaultClaimableTVL;
    }
}
