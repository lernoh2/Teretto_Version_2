// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "/.deps/github/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC777/ERC777.sol";
import "/.deps/github/OpenZeppelin/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

    contract Test_Redistributor_TokenT2V107 is ERC777 {
    using SafeMath for uint256;
    address public owner;
    address public presale;
    uint256 communityShare = 80;
    bool private presaleSet = false;
    
    event TransferSentToL(address from, address redistributor, uint256 redAmount);
    event TransferSent(address from, address recipient, uint256 amount);
    event TransferForTrade(address from, address recipient, uint256 amount);
   

    constructor() ERC777("Test2V107", "T2V107", new address[](0)) {
        _mint(msg.sender, 9000 * 10 ** 18, "", "");
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }


    struct Destination 
    {
        address payable redistributor;
        string name;    
    }
    
    Destination[8] public destinations;
    uint256 private destinationCount;

    function addDestination(address payable redistributor, string memory name) 
        public onlyOwner 
    {
        require(destinationCount < 8, "Maximum number of destinations reached.");
        require(msg.sender == owner, "Only the owner can set this struct");
        destinations[destinationCount] = Destination(redistributor, name);
        destinationCount++;
    }

    function setPresale(address _presale) external onlyOwner {
        require(_presale != address(0), "Invalid address");
        require(!presaleSet, "Presale address has already been set.");
        presale = _presale;
        presaleSet = true;
    }


 function transfer(address recipient, uint256 amount) public override returns (bool) {
    address sender = _msgSender();
      // Check if the recipient is one of the redistributors and the sender is not the presale
    for (uint i = 0; i < destinations.length; i++) {
        if (recipient == destinations[i].redistributor || sender == destinations[i].redistributor || sender == owner) {
            require(amount != 1 * 10 ** 18, "You cant send directly this amount");
            // Send 100% of the amount to the redistributor
            _send(_msgSender(), recipient, amount, "", "", false);
            emit TransferForTrade(sender, recipient, amount);
            return true;
        }
    }
        
        if (sender == presale) {
       
        _send(msg.sender, recipient, amount, "", "", true);
       
        return true;

    } else {
        require(amount == 10 * 10 ** 18);
        // calculate the community fee
         uint256 communityFee = amount * communityShare / 100;
        // send the community fee to the redistributors
        for (uint i = 0; i < destinations.length; i++) { 
            _send(msg.sender, destinations[i].redistributor, communityFee / destinations.length, "", "", true);
            emit TransferSentToL(msg.sender, destinations[i].redistributor, communityFee / destinations.length);    
        }

        // send the remaining amount to the recipient
        _send(msg.sender, recipient, amount.sub(communityFee), "", "", true);
        emit TransferSent(msg.sender, recipient, amount);
        return true;
    }
  }

    }