/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.6.0;

import "./Frozen.sol";
import "./DistributionsCompat.sol";

/*
    Distribution that is frozen (while exporting/migrating) compatible with L1/Rinkeby and older OZ libraries (2.x)
*/

contract DistributionsFrozenCompat is DistributionsCompat, Frozen {
    function initialize(
        address owner_,
        address subredditPoints_,                    // ISubredditPoints + IERC20 token contract address
        address karmaSource_,                        // Karma source provider address
        address gsnApprover_,                        // GSN approver address

        uint256 initialSupply_,
        uint256 nextSupply_,
        uint256 initialKarma_,
        uint256 roundsBeforeExpiration_,              // how many rounds are passed before claiming is possible
        uint256 supplyDecayPercent_,                  // defines percentage of next rounds' supply from the current
        address[] calldata sharedOwners_,
        uint256[] calldata sharedOwnersPercs_           // index of percentages must correspond to _sharedOwners array
    ) external frozen {
    }

    function claim(uint256 round, address account, uint256 karma, bytes calldata signature) external frozen {
    }

    function advanceToRound(uint256 round, uint256 totalKarma) external frozen {
    }

    function totalSharedOwners() external view returns (uint256) {
        return sharedOwners.length;
    }

    function updateSupplyDecayPercent(uint256 _supplyDecayPercent) public frozen {
    }

    function updateRoundsBeforeExpiration(uint256 _roundsBeforeExpiration) public frozen {
    }

    function minClaimableRound() public view returns (uint256) {
        if (lastRound >= roundsBeforeExpiration) {
            return lastRound - roundsBeforeExpiration;
        }
        return 0;
    }

    function updateKarmaSource(address _karmaSource) external frozen {
    }

    function updateGSNApprover(address gsnApprover) external onlyOwner {
        updateSigner(gsnApprover);
    }

    function updateSharedOwner(address account, uint256 percent) external frozen {
    }


    function percentPrecision() external pure returns (uint256) {
        return PERCENT_PRECISION;
    }

    function prevRoundSupply() external view returns (uint256) {
        return _prevRoundSupply;
    }

    function prevClaimed() external view returns (uint256) {
        return _prevClaimed;
    }

    function roundAvailablePoints(uint256 round) external view returns (uint256) {
        return _distributionRounds[round].availablePoints;
    }

    function roundSharedOwnersAvailablePoints(uint256 round) external view returns (uint256) {
        return _distributionRounds[round].sharedOwnersAvailablePoints;
    }

    function roundTotalKarma(uint256 round) external view returns (uint256) {
        return _distributionRounds[round].totalKarma;
    }
}
