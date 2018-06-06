pragma solidity ^0.4.24;

//Author: Bruno Block
//Version: 0.3

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
    uint256 public transferSafety;

    event Proposal(uint256 _nonce, address _author, address _contract, uint256 _amount, address _destination, uint256 _timestamp);

    event Accept(uint256 _nonce);

    event NewDirectorA(address _director);

    event NewDirectorB(address _director);

    modifier onlyDirectors {
        require(msg.sender == directorA || msg.sender == directorB);
        _;
    }

    constructor() public {
        overrideTime = 60*60*24*30;//one month override interval
        proposalNonce = 0;
        transferSafety = 1 ether;
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

    function accept(uint256 acceptNonce) public onlyDirectors {
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

    function transferDirectorA(address newDirectorA) public payable {
        require(msg.sender==directorA);
        require(msg.value==transferSafety);// Prevents accidental transfer
        directorA.transfer(transferSafety);// Reimburse safety deposit
        reset();
        directorA = newDirectorA;
        emit NewDirectorA(directorA);
    }

    function transferDirectorB(address newDirectorB) public payable {
        require(msg.sender==directorB);
        require(msg.value==transferSafety);// Prevents accidental transfer
        directorB.transfer(transferSafety);// Reimburse safety deposit
        reset();
        directorB = newDirectorB;
        emit NewDirectorB(directorB);
    }
}