// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "/.deps/github/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC777/ERC777.sol";
import "/.deps/github/OpenZeppelin/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

contract Te_Re_To_V2 is ERC777 {
    using SafeMath for uint256;
    address public owner;
    address public starter;
    uint256 immutable communityShare = 90;
    bool private starterSet = false;

    event TransferSentToL(address from, address redistributor, uint256 redAmount);
    event TransferSent(address from, address recipient, uint256 amount);
    event TransferForTrade(address from, address recipient, uint256 amount);

   constructor() ERC777("ETTO_Version_2", "ETTO_V2", new address[](0)) {
        _mint(msg.sender, 41000 * 10 ** 18, "", "");
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    struct Destination {
        address payable redistributor;
        string name;    
    }
    
    Destination[9] public destinations;
    uint256 private destinationCount;

    function addDestination(address payable redistributor, string memory name) 
        public 
        onlyOwner 
    {
        require(destinationCount < 9, "Maximum number of destinations reached.");
        destinations[destinationCount] = Destination(redistributor, name);
        destinationCount++;
    }

    function setStarter(address _starter) external onlyOwner {
        require(_starter != address(0), "Invalid address");
        require(!starterSet, "Presale address has already been set.");
        starter = _starter;
        starterSet = true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        address sender = _msgSender();

        // Check if the transfer involves redistributors or the owner
        for (uint i = 0; i < destinations.length; i++) {
            if (recipient == destinations[i].redistributor || sender == destinations[i].redistributor || sender == owner) {
                require(amount != 1 * 10 ** 18, "You can't send this amount directly.");
                _send(sender, recipient, amount, "", "", false);
                emit TransferForTrade(sender, recipient, amount);
                return true;
            }
        }

        // If the sender is the presale contract
        if (sender == starter) {
            _send(sender, recipient, amount, "", "", true);
            return true;
        }

        // Special behavior when transferring exactly 10 tokens
        if (amount == 10 * 10 ** 18) {
            uint256 communityFee = amount * communityShare / 100;
            // Distribute the community fee among redistributors
            for (uint i = 0; i < destinations.length; i++) { 
            _send(msg.sender, destinations[i].redistributor, communityFee / destinations.length, "", "", true);
            emit TransferSentToL(msg.sender, destinations[i].redistributor, communityFee / destinations.length);    
            }

            // Send the remaining 10% to the recipient
            _send(msg.sender, recipient, amount.sub(communityFee), "", "", true);
            emit TransferSent(sender, recipient, amount);
            return true;
        }

        // Default behavior for all other amounts
        _send(sender, recipient, amount, "", "", false);
        emit TransferSent(sender, recipient, amount);
        return true;
    }
}
