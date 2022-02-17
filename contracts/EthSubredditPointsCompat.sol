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

import "./EthSubredditPointsObsoleteCompat.sol";
import "./IEthBridgedToken.sol";

interface IL1CustomGatewayCompat {
    function router() external returns (address);
    function registerTokenToL2(
        address _l2Address,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable returns (uint256);

    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);
}

interface IL1GatewayRouterCompat {
    function setGateway(
        address _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable returns (uint256);
}

/*
    L1 SubredditPoints ERC20 token, pairable to L2 and supports L1<->L2 withdrawals/deposits.
    Compatible with Rinkeby implementation/OZ 2.x libraries.
*/

contract EthSubredditPointsCompat is EthSubredditPointsObsoleteCompat, IEthBridgedToken {
    using SafeMath for uint256;
    using Address for address;

    event TransferredFromL2(address indexed source, address indexed destination, uint256 amount, bytes userData);
    event TransferredToL2(address indexed source, address indexed destination, uint256 amount, bytes userData, uint256 seqNum);

    modifier onlyGateway {
        require(msg.sender == address(gateway), "Call only from gateway");
        _;
    }

    modifier disabled() {
        revert("Method is disabled");
        _;
    }

    // ------------------------------------------------------------------------------------
    // VARIABLES BLOCK, MAKE SURE ONLY ADD TO THE END

    IL1CustomGatewayCompat public gateway;
    address public l2Address;

    // END OF VARS
    // ------------------------------------------------------------------------------------

    function initialize(address owner_, string calldata subreddit_, string calldata name_,
        string calldata symbol_, address gateway_, address l2Address_)
        external initializer
    {
        require(gateway_ != address(0), "gateway should not be 0");
        require(l2Address_ != address(0), "l2Address should not be 0");

        gateway = IL1CustomGatewayCompat(gateway_);
        l2Address = l2Address_;

        require(bytes(subreddit_).length != 0, "SubredditPoints: subreddit can't be empty");
        require(bytes(name_).length != 0, "SubredditPoints: name can't be empty");
        require(bytes(symbol_).length != 0, "SubredditPoints: symbol can't be empty");
        require(owner_ != address(0), "SubredditPoints: owner should not be 0");

        OwnableCompat.initialize(owner_);
        //UpdatableGSNRecipientSignatureCompat.initialize(gsnApprover_);
        //updateDistributionContract(distributionContract_);

        _subreddit = subreddit_;
        _name = name_;
        _symbol = symbol_;
    }

    function initializeL2(address gateway_, address l2Address_)
        external onlyOwner
    {
        require(gateway_ != address(0), "gateway should not be 0");
        require(l2Address_ != address(0), "l2Address should not be 0");

        gateway = IL1CustomGatewayCompat(gateway_);
        l2Address = l2Address_;
    }

    // ------------------------------------------------------------------------------------
    // Disabled functions

    function mint(
        address operator,
        address account,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external disabled { }

    function isOperatorFor(
        address operator,
        address tokenHolder
    ) public view returns (bool) {
        return false;
    }

    function authorizeOperator(address operator) external disabled { }

    function revokeOperator(address operator) external disabled { }

    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external disabled { }

    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external disabled { }

    function defaultOperators() external view returns (address[] memory) {
        return new address[](0);
    }

    function addDefaultOperator(address operator) external onlyOwner disabled { }

    function removeDefaultOperator(address operator) external onlyOwner disabled { }

    // ------------------------------------------------------------------------------------
    // L2 compatibility functions

    function registerTokenToL2(uint256 maxGas, uint256 gasPriceBid, uint256 maxSubmissionCost) external onlyOwner {
        gateway.registerTokenToL2(
            l2Address,
            maxGas / 2,
            gasPriceBid,
            maxSubmissionCost / 2
        );

        address router = gateway.router();
        IL1GatewayRouterCompat(router).setGateway(address(gateway),
            maxGas / 2,
            gasPriceBid,
            maxSubmissionCost / 2
        );
    }

    function bridgeMint(address account, uint256 amount) external onlyGateway {
        _mint(account, amount);
    }

    function bridgeBurn(address account, uint256 amount) external onlyGateway {
        super._burn(account, amount);
    }
}
