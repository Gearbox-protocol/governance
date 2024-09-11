// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {QueryOutput} from "./ILPNRegistryV1.sol";

/**
 * @title ILPNClient
 * @notice Interface for the LPNClientV0 contract.
 */
interface ILPNClientV1 {
    /// @notice Callback function called by the LPNRegistry contract.
    /// @param requestId The ID of the request.
    /// @param result The result of the request.
    function lpnCallback(uint256 requestId, QueryOutput calldata result) external;
}
