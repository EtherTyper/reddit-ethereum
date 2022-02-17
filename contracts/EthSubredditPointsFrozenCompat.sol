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

import "./EthSubredditPointsCompat.sol";

/*
    L1 SubredditPoints ERC20 token that's used while migrating/exporting points to L2
    Compatible with Rinkeby implementation/OZ 2.x libraries.
*/

contract EthSubredditPointsFrozenCompat is EthSubredditPointsCompat {
    modifier onlyOwnerOrGateway() {
        require(isOwner() || _msgSender() == address(gateway), "Only owner or gateway can call this");
        _;
    }

    function depositToL2(address[] calldata accounts, uint256 maxGas, uint256 gasPriceBid, uint256 maxSubmissionCost)
        external onlyOwner {

        bytes memory emptyBytes = "";
        bytes memory data = abi.encode(maxSubmissionCost, emptyBytes);
        for (uint256 i = 0; i < accounts.length; ++i) {
            address account = accounts[i];
            uint256 amount = balanceOf(account);
            if (amount > 0) {
                _transfer(account, address(this), amount);
                gateway.outboundTransfer(address(this), account, amount, maxGas, gasPriceBid, data);
            }
        }
    }

    function _mint(address account, uint256 amount) internal onlyOwnerOrGateway {
        super._mint(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal onlyOwnerOrGateway {
        super._transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal onlyOwnerOrGateway {
        super._approve(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) internal onlyOwnerOrGateway {
        super._burn(account, amount);
    }

    function _burnFrom(address account, uint256 amount) internal onlyOwnerOrGateway {
        super._burnFrom(account, amount);
    }
}
