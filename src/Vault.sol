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
    mapping(uint256 => bool) isEpochValid;

    mapping(uint256 => uint256[]) public epochSpan;

    mapping(uint256 => bool) public stopDeposits;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error AddressZero();
    error SenderNotOwner();
    error DepositPeriodEnded();
    error WithdrawPeriodNotStarted();
    error EpochNotExpired();

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        ERC20 _asset,
        string memory _name, // PGB-MIM-998-epoc'h#RISK
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

    function startNewEpoch(uint256 epochStart, uint256 epochEnd) public {
        epochSpan[epochEnd] = [epochStart, epochEnd];
        epochState[epochEnd] = 0;
        epochs.push(epochEnd);
        isEpochValid[epochEnd] = true;
    }

    function setEpochState(
        uint256 _epochId,
        uint8 state
    ) public onlyController {
        require(isEpochValid[_epochId], "Vault: epoch id is not valid");
        epochState[_epochId] = state;
    }

    event Deposit(uint256[] timestamps);
    event CurrentTime(uint256 timestamp);

    function deposit(
        uint256 amount,
        uint256 epochId,
        address receiver
    ) public nonReentrant {
        require(amount > 0, "Vault: amount must be greater than 0");
        require(isEpochValid[epochId] == true, "Vault: market is not valid");
        emit Deposit(epochSpan[epochId]);
        emit CurrentTime(block.timestamp);
        if (
            epochSpan[epochId][0] <= block.timestamp &&
            epochSpan[epochId][0] + 2 days > block.timestamp
        ) {
            asset.transferFrom(receiver, address(this), amount);
            mint(receiver, epochId, amount, "");
        } else {
            revert DepositPeriodEnded();
        }
    }

    function depositEth(
        uint256 epochId,
        address receiver
    ) public payable nonReentrant {
        require(msg.value > 0, "Vault: amount must be greater than 0");
        require(isEpochValid[epochId] == true, "Vault: market is not valid");

        if (
            (epochSpan[epochId][0] <= block.timestamp &&
                epochSpan[epochId][0] + 2 days > block.timestamp)
        ) {
            mint(receiver, epochId, msg.value, "");
        } else {
            revert DepositPeriodEnded();
        }
    }

    function withdraw(
        uint256 amount,
        uint256 epochId,
        address owner,
        address receiver
    ) public {
        require(amount > 0, "Vault: amount must be greater than 0");
        require(isEpochValid[epochId] == true, "Vault: market is not valid");
        if (owner != msg.sender) revert SenderNotOwner();

        if (block.timestamp < epochSpan[epochId][1]) {
            revert EpochNotExpired();
        }
        if (epochState[epochId] != 1) {
            revert WithdrawPeriodNotStarted();
        }

        _burn(owner, epochId, amount);

        uint256 eligibleAmount = withdrawConversion(epochId, amount);
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
        require(isEpochValid[epochId], "Vault: epoch id is not valid");
        vaultClaimabeTVL[epochId] = _vaultClaimableTVL;
    }

    function setDepositStop(
        uint256 epochId,
        bool _stopDeposits
    ) public onlyController {
        require(isEpochValid[epochId], "Vault: epoch id is not valid");
        stopDeposits[epochId] = _stopDeposits;
    }
}
