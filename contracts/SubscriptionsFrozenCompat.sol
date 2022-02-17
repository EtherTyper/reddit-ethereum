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

import "./SubscriptionsCompat.sol";
import "./Frozen.sol";

/*
    Used while exporting subscriptions from L1 -> L2
    Compatible with Rinkeby implementation/OZ 2.x libraries.
*/

contract SubscriptionsFrozenCompat is SubscriptionsCompat, Frozen {
    function initialize(
        address owner_,
        address gsnApprover,
        address subredditPoints,
        uint256 price_,
        uint256 duration_,
        uint256 renewBefore_
    ) external frozen {
    }

    function cancel(address recipient) external frozen {
    }

    function renew(address recipient) external frozen {
    }

    function subscribe(address recipient, bool renewable) external frozen {
    }

    function updateDuration(uint256 duration_) public frozen {
    }

    function updatePrice(uint256 price_) public frozen {
    }

    function updateRenewBefore(uint256 renewBefore_) public frozen {
    }

    function duration() external view returns (uint256) {
        return _duration;
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function renewBefore() external view returns (uint256) {
        return _renewBefore;
    }

    function expiration(address account) public view returns (uint256) {
        return _subscriptions[account];
    }

    function updateGSNApprover(address gsnApprover) external frozen {
    }

    function payerOf(address account) public view returns (address) {
        return _payers[account];
    }
}
