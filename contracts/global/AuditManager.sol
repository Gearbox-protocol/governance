// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {SanityCheckTrait} from "@gearbox-protocol/core-v3/contracts/traits/SanityCheckTrait.sol";
import {IncorrectParameterException} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

import {SecurityReport, AuditorInfo} from "../interfaces/Types.sol";

interface IAuditManagerEvents {
    /// @dev Emitted when a new auditor is added to the set
    event AddAuditor(address indexed auditor, string name);

    /// @dev Emitted when an auditor is forbidden
    event ForbidAuditor(address indexed auditor, string name);
}

interface IAuditManagerExceptions {
    /// @dev Thrown when an attempt is made to add an auditor that already exists
    error AuditorAlreadyAddedException();

    /// @dev Thrown when an auditor is not found in the set
    error AuditorNotFoundException();

    /// @dev Thrown if the caller does not have valid auditor permissions
    error NotValidAuditorPermissionsException();
}

contract AuditManager is Ownable2Step, SanityCheckTrait, IAuditManagerEvents, IAuditManagerExceptions {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Set of all known auditors
    EnumerableSet.AddressSet internal _auditors;

    /// @dev Mapping from auditor address to their info (name and whether they are forbidden)
    mapping(address => AuditorInfo) public auditorInfo;

    /// @dev Mapping from object hash to set of all its audits
    mapping(bytes32 => SecurityReport[]) public securityReports;

    /// @notice Adds a new auditor to the auditor list
    function addAuditor(address auditor, string memory _name) external onlyOwner nonZeroAddress(auditor) {
        if (bytes(_name).length == 0) {
            revert IncorrectParameterException();
        }
        if (_auditors.contains(auditor)) {
            revert AuditorAlreadyAddedException();
        }

        _auditors.add(auditor);
        auditorInfo[auditor].name = _name;
        emit AddAuditor(auditor, _name);
    }

    /// @notice Forbids an auditor, which prevents them from submitting new audits and invalidates
    ///         their previous audits
    function forbidAuditor(address auditor) external onlyOwner nonZeroAddress(auditor) {
        if (!_auditors.contains(auditor)) {
            revert AuditorNotFoundException();
        }

        auditorInfo[auditor].forbidden = true;
        emit ForbidAuditor(auditor, auditorInfo[auditor].name);
    }

    /// @dev Adds a new security report for a key (what constitutes a key is specific to inheriting contract)
    function _addSecurityReport(bytes32 key, address auditor, string calldata reportUrl) internal {
        if (!_auditors.contains(auditor) || auditorInfo[auditor].forbidden) {
            revert NotValidAuditorPermissionsException();
        }

        securityReports[key].push(SecurityReport({auditor: auditor, url: reportUrl}));
    }

    /// @dev Returns a number of unique non-forbidden auditors for a particular key (what constitutes a key is specific to inheriting contract)
    function _getUniqueNonForbiddenAuditorCount(bytes32 key) internal view returns (uint256 count) {
        SecurityReport[] memory reports = securityReports[key];

        uint256 len = reports.length;

        address[] memory foundAuditors = new address[](len);
        uint256 k = 0;

        for (uint256 i = 0; i <= len; ++i) {
            address auditor = reports[i].auditor;

            for (uint256 j = 0; j <= k; ++j) {
                if (j == k) {
                    foundAuditors[k] = auditor;
                    ++k;
                    if (!auditorInfo[auditor].forbidden) ++count;
                }

                if (auditor == foundAuditors[j]) break;
            }
        }
    }
}
