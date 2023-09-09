// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TeamWallet {

    bool execute = false;
    uint256 credit;
    uint totalMemberCount;
    address owner;
    enum Stats{
        Pending,
        Debited,
        Failed
    }

    struct Trans {
        Stats stats;
        uint256 amount;
        uint voteApprove;
        uint voteReject;
    }


    Trans[] allTx;
    mapping(address => bool) member;
    mapping(uint256 => mapping(address => bool)) hasVoted;

    constructor(){
        owner = msg.sender;
    }

    //For setting up the wallet
    function setWallet(address[] memory _members, uint256 _credtis) public {
        require(!execute && msg.sender == owner);
        execute = true;
        require(_members.length > 0 && _credtis > 0);
        credit = _credtis;
        for(uint i=0;i<_members.length;i++){
            require(_members[i] != owner);
            member[_members[i]] = true;
            totalMemberCount++;
        }
    }

    //For spending amount from the wallet
    function spend(uint256 amount) public {
        checkMember();
        require(amount > 0);
        Trans memory newTransaction = Trans({
            stats: Stats.Pending,
            amount: amount,
            voteApprove: 1,
            voteReject: 0 
        });
        if (newTransaction.amount > credit) newTransaction.stats = Stats.Failed;
        if (((newTransaction.voteApprove * 100) / totalMemberCount) >= 70 && newTransaction.stats == Stats.Pending) {
            require(credit >= newTransaction.amount);
            credit -= newTransaction.amount;
            newTransaction.stats = Stats.Debited;
        }
        allTx.push(newTransaction);
        hasVoted[allTx.length - 1][msg.sender] = true;

    }

    //For approving a transaction request
    function approve(uint256 n) public {
        checkMember();
        require(n-1 < allTx.length);
        Trans storage transaction = allTx[n-1];
        require(transaction.stats == Stats.Pending);
        require(!hasVoted[n-1][msg.sender]);
        transaction.voteApprove++;
        hasVoted[n-1][msg.sender] = true;
        
        if ((transaction.voteApprove * 100) / totalMemberCount >= 70) {
            require(credit >= transaction.amount);
            if (transaction.amount > credit) {
                transaction.stats = Stats.Failed;
                return;
            }
            credit -= transaction.amount;
            transaction.stats = Stats.Debited;
        }
    }

    //For rejecting a transaction request
    function reject(uint256 n) public {
        checkMember();
        require(n-1 < allTx.length);
        Trans storage transaction = allTx[n-1];
        require(transaction.stats == Stats.Pending);
        require(!hasVoted[n-1][msg.sender]);
        transaction.voteReject++;
        hasVoted[n-1][msg.sender] = true;

        if ((transaction.voteReject * 100) / totalMemberCount >= 30) {
            transaction.stats = Stats.Failed;
        }
    }

    //For checking remaing credits in the wallet
    function credits() public view returns (uint256) {
        checkMember();
        return credit;
    }

    //For checking nth transaction status
    function viewTransaction(uint256 n) public view returns (uint, string memory) {
    checkMember();
    require(n-1 < allTx.length, "Invalid transaction index");
    Trans storage transaction = allTx[n-1];
    if (transaction.stats == Stats.Pending) {
        return (transaction.amount, "pending");
    } else if (transaction.stats == Stats.Debited) {
        return (transaction.amount, "debited");
    } else if (transaction.stats == Stats.Failed) {
        return (transaction.amount, "failed");
    } else {
        // Handle any other cases or revert with an error message
        revert("Invalid transaction status");
    }
}


    //For checking the transaction stats for the wallet
    function transactionStats() public view returns (uint debitedCount,uint pendingCount,uint failedCount){
        checkMember();
        for(uint i=0;i<allTx.length;i++){
            Trans storage transaction = allTx[i];
            if (transaction.stats == Stats.Pending) pendingCount++;
            else if (transaction.stats == Stats.Debited) debitedCount++;
            else if (transaction.stats == Stats.Failed) failedCount++;
        }
        return (debitedCount, pendingCount, failedCount);
    }

    function checkMember() public view {
        require(member[msg.sender]);
    }
}