pragma solidity ^0.4.23;

//Author: Bruno Block
//Version: 0.2

interface contractInterface {
    function balanceOf(address _owner) external constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) external;
}

contract DualSig {
    address public directorA;
    address public directorB;
    address public proposalAuthor;
    address public proposalContract;
    uint256 public proposalAmount;
    address public proposalDestination;
    uint256 public proposalTimestamp;
    uint256 public proposalNonce;
    uint256 public overrideTime;

    event Proposal(uint8 _nonce, address _author, address _contract, uint256 _amount, address _destination, uint256 _timestamp);

    event Accept(uint8 _nonce);

    modifier onlyDirectors {
        require(msg.sender == directorA || msg.sender == directorB);
        _;
    }

    constructor() public {
        overrideTime = 5259492;//two month override interval
        proposalNonce = 0;
        directorA = msg.sender;
        directorB = msg.sender;
        reset();
    }

    function proposal(address proposalContractSet, uint256 proposalAmountSet, address proposalDestinationSet) public onlyDirectors {
        proposalNonce++;
        proposalAuthor = msg.sender;
        proposalContract = proposalContractSet;
        proposalAmount = proposalAmountSet;
        proposalDestination = proposalDestinationSet;
        proposalTimestamp = block.timestamp + overrideTime;
        emit Proposal(proposalNonce, proposalAuthor, proposalContract, proposalAmount, proposalDestination, proposalTimestamp);
    }

    function reset() public onlyDirectors {
        proposalNonce++;
        proposalAuthor = 0x0;
        proposalContract = 0x0;
        proposalAmount = 0;
        proposalDestination = 0x0;
        proposalTimestamp = 0;
    }

    function accept(uint8 acceptNonce) public onlyDirectors {
        require(proposalNonce == acceptNonce);
        require(proposalAmount > 0);
        require(proposalDestination != 0x0);
        require(proposalAuthor != msg.sender || block.timestamp >= proposalTimestamp);

        if (proposalContract==0x0) {
            require(proposalAmount <= address(this).balance);
            proposalDestination.transfer(proposalAmount);
        }
        else {
            contractInterface tokenContract = contractInterface(proposalContract);
            tokenContract.transfer(proposalDestination, proposalAmount);
        }
        emit Accept(acceptNonce);
        reset();
    }

    function transferDirectorA(address newDirectorA) public {
        require(msg.sender==directorA);
        reset();
        directorA = newDirectorA;
    }

    function transferDirectorB(address newDirectorB) public {
        require(msg.sender==directorB);
        reset();
        directorB = newDirectorB;
    }
}