// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";

import {ILPNClient} from "../interfaces/lagrange/ILPNClient.sol";
import {ILPNRegistry} from "../interfaces/lagrange/ILPNRegistry.sol";
import {QueryParams} from "../interfaces/lagrange/QueryParams.sol";
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

    /// @notice Thrown when a holder has already claimed their rewards for a campaign
    error AlreadyClaimed();
}

/// @dev Precision for the propotional balance integral
uint256 constant PROPORTIONAL_BALANCE_PRECISION = 10 ** 18;

contract LagrangeDistributor is Ownable, ILPNClient, ILagrangeDistributorExceptions, ILagrangeDistributorEvents {
    using QueryParams for QueryParams.ERC20QueryParams;
    using SafeERC20 for IERC20;

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
    /// @param results The result of the request.
    function lpnCallback(uint256 requestId, uint256[] calldata results) external lpnRegistryOnly {
        uint256 campaignId = requestData[requestId].campaignId;
        address holder = requestData[requestId].holder;
        uint256 integral = results[0];

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
        CampaignData campaign = _campaigns[campaignId];

        uint256 blockLU = campaign.blockLU[holder];
        uint256 startBlock = campaign.startBlock;
        uint256 endBlock = campaign.endBlock;

        startBlock = blockLU > startBlock ? blockLU : startBlock;
        endBlock = block.number > endBlock ? endBlock : block.number;
        endBlock = endBlock - 1;

        uint256 maxQueryRange = ILPNRegistry(lpnRegistry).MAX_QUERY_RANGE();
        uint256 queryRange = (endBlock - startBlock) + 1;

        if (queryRange > maxQueryRange) {
            endBlock = startBlock + queryRange - 1;
        }

        // TODO: this can be removed since LPNRegistry.request will revert
        if (startBlock > endBlock) {
            revert AlreadyClaimed();
        }

        uint256 requestId = ILPNRegistry(lpnRegistry).request{value: ILPNRegistry(lpnRegistry).gasFee()}(
            queriedToken,
            QueryParams.newERC20QueryParams(holder, uint88(PROPORTIONAL_BALANCE_PRECISION)).toBytes32(),
            startBlock,
            endBlock
        );

        _campaigns[campaignId].blockLU[holder] = endBlock + 1;
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
                msg.sender, address(this), rewards[i].rewardRate * (endBlock - startBlock + 1)
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
