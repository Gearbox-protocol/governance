// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";

import {ILPNClientV1} from "../interfaces/lagrange/ILPNClientV1.sol";
import {ILPNRegistryV1, QueryOutput} from "../interfaces/lagrange/ILPNRegistryV1.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct RewardData {
    /// @dev Address of the reward token
    address rewardToken;
    /// @dev Reward rate per block
    uint96 rewardRate;
}

struct CampaignData {
    /// @dev Timestamp of campaign start
    uint256 startBlock;
    /// @dev Timestamp of campaign end
    uint256 endBlock;
    /// @dev List of reward tokens and their reward rates
    RewardData[] rewards;
    /// @dev Mapping from holder address to the last timestamp when they claimed this campaign
    mapping(address => uint256) blockLU;
}

struct RequestData {
    /// @dev ID of the campaign for which the request is made
    uint256 campaignId;
    /// @dev Address of the token holder for which the request is made
    address holder;
}

interface ILagrangeDistributorEvents {
    /// @notice Emitted when a token holder claims their reward
    event RewardClaimed(address indexed holder, uint256 indexed campaignId, address indexed token, uint256 amount);

    /// @notice Emitted when a new campaign is started
    event CampaignStarted(uint256 indexed campaignId, uint256 startBlock, uint256 endBlock);

    /// @notice Emitted when a campaign is ended prematurely
    event CampaignEnded(uint256 indexed campaignId, uint256 newEndBlock);
}

interface ILagrangeDistributorExceptions {
    /// @notice Thrown when registry-only function is called by address other than registry
    error CallerNotLPNRegistryException();

    /// @notice Thrown when attempting to end the campaign on a block that is larger than the old end block
    error NewEndBlockLargerThanOldException();
}

/// @dev Precision for the propotional balance integral
uint256 constant PROPORTIONAL_BALANCE_PRECISION = 10 ** 18;

contract LagrangeDistributor is Ownable, ILPNClientV1, ILagrangeDistributorExceptions, ILagrangeDistributorEvents {
    using SafeERC20 for IERC20;

    /// @notice Columns expected in the query result
    struct ExpectedResultRow {
        uint256 integral;
    }

    // TODO: Register a query and fill this in
    /// @notice The query hash corresponding to a proportionate balance query of a particular ERC20 table
    bytes32 public constant GEARBOX_PROPORTIONATE_BALANCE_QUERY_HASH =
        0x0000000000000000000000000000000000000000000000000000000000000000;

    /// @notice Address of the LPN registry
    address public immutable lpnRegistry;

    /// @notice Storage slot of balances in queried ERC20
    uint256 public immutable balanceOfStorageSlot;

    /// @notice The token that is being tracked to distribute rewards
    address public immutable queriedToken;

    /// @notice Mapping from campaign ID to its data
    mapping(uint256 => CampaignData) internal _campaigns;

    /// @notice Total number of created campaigns
    uint256 public campaignCount;

    /// @notice Mapping from request ID to the campaign ID and holder it is made for
    mapping(uint256 => RequestData) public requestData;

    modifier lpnRegistryOnly() {
        if (msg.sender != lpnRegistry) revert CallerNotLPNRegistryException();
        _;
    }

    constructor(address _lpnRegistry, address _queriedToken, uint256 _balanceOfStorageSlot) {
        lpnRegistry = _lpnRegistry;
        queriedToken = _queriedToken;
        _balanceOfStorageSlot = _balanceOfStorageSlot;
    }

    /// @notice Callback function called by the LPNRegistry contract.
    /// @param requestId The ID of the request.
    /// @param result The result of the request.
    function lpnCallback(uint256 requestId, QueryOutput calldata result) external lpnRegistryOnly {
        uint256 campaignId = requestData[requestId].campaignId;
        address holder = requestData[requestId].holder;

        if (result.rows.length == 0) return;

        uint256 integral = abi.decode(result.rows[0], (ExpectedResultRow)).integral;

        if (integral == 0) return;

        RewardData[] storage rewards = _campaigns[campaignId].rewards;

        uint256 len = rewards.length;

        for (uint256 i = 0; i < len;) {
            address rewardToken = rewards[i].rewardToken;
            uint256 amount = integral * rewards[i].rewardRate / PROPORTIONAL_BALANCE_PRECISION;

            IERC20(rewardToken).safeTransfer(holder, amount);

            emit RewardClaimed(holder, campaignId, rewardToken, amount);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Function that initiates a query for a proportional balance integral over the campaign period
    /// @param holder Address of the token holder
    /// @param campaignId Id of the campaign
    function queryCumulativeProportionateBalance(address holder, uint256 campaignId) public payable {
        uint256 blockLU = _campaigns[campaignId].blockLU[holder];
        uint256 startBlock = _campaigns[campaignId].startBlock;
        uint256 endBlock = _campaigns[campaignId].endBlock;

        startBlock = blockLU > startBlock ? blockLU : startBlock;
        endBlock = block.number > endBlock ? endBlock : block.number;
        endBlock = endBlock - 1;

        bytes32[] memory placeholders = new bytes32[](2);
        placeholders[0] = bytes32(bytes20(holder));
        placeholders[1] = bytes32(PROPORTIONAL_BALANCE_PRECISION);

        uint256 requestId = ILPNRegistryV1(lpnRegistry).request{value: ILPNRegistryV1(lpnRegistry).gasFee()}(
            GEARBOX_PROPORTIONATE_BALANCE_QUERY_HASH, placeholders, startBlock, endBlock
        );

        _campaigns[campaignId].blockLU[holder] = block.number;
        requestData[requestId] = RequestData({campaignId: campaignId, holder: holder});
    }

    /// @notice Function that initiates a query for a proportional balance integral over the campaign period for several campaigns
    /// @param holder Address of the token holder
    /// @param campaignIds Ids of all campaigns
    function multiQueryCumulativeProportionateBalance(address holder, uint256[] calldata campaignIds)
        external
        payable
    {
        uint256 len = campaignIds.length;

        for (uint256 i = 0; i < len;) {
            queryCumulativeProportionateBalance(holder, campaignIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Starts a reward distribution campaign and transfers total rewards from the owner
    /// @param startBlock Block when the campaign starts
    /// @param endBlock Block when the campaign ends
    /// @param rewards Array of (token, rewardRate) pairs for each reward token
    function startCampaign(uint256 startBlock, uint256 endBlock, RewardData[] calldata rewards) external onlyOwner {
        uint256 campaignId = campaignCount;

        _campaigns[campaignId].startBlock = startBlock;
        _campaigns[campaignId].endBlock = endBlock;

        uint256 len = rewards.length;

        for (uint256 i = 0; i < len; ++i) {
            _campaigns[campaignId].rewards.push(rewards[i]);
            IERC20(rewards[i].rewardToken).safeTransferFrom(
                msg.sender, address(this), rewards[i].rewardRate * (endBlock - startBlock)
            );

            unchecked {
                ++i;
            }
        }

        ++campaignCount;

        emit CampaignStarted(campaignId, startBlock, endBlock);
    }

    /// @notice Ends the campaign prematurely and returns remaining rewards to the owner
    /// @param campaignId ID of the campaign
    /// @param newEndBlock The block at which the campaign will end prematurely
    function endCampaign(uint256 campaignId, uint256 newEndBlock) external onlyOwner {
        uint256 endBlock = _campaigns[campaignId].endBlock;
        if (newEndBlock > endBlock) revert NewEndBlockLargerThanOldException();

        uint256 remainingBlocks = endBlock - newEndBlock;

        RewardData[] storage rewards = _campaigns[campaignId].rewards;

        uint256 len = rewards.length;

        for (uint256 i = 0; i < len;) {
            IERC20(rewards[i].rewardToken).safeTransfer(msg.sender, remainingBlocks * rewards[i].rewardRate);

            unchecked {
                ++i;
            }
        }

        _campaigns[campaignId].endBlock = newEndBlock;

        emit CampaignEnded(campaignId, newEndBlock);
    }

    /// @notice Returns information on the campaign
    /// @param campaignId ID of the campaign
    function getCampaignData(uint256 campaignId)
        external
        view
        returns (uint256 startBlock, uint256 endBlock, RewardData[] memory rewards)
    {
        startBlock = _campaigns[campaignId].startBlock;
        endBlock = _campaigns[campaignId].endBlock;
        rewards = _campaigns[campaignId].rewards;
    }
}
