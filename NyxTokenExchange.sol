/*
* Copyright © 2018 NYX. All rights reserved.
* Author Andrey Nagovitsyn
*/

// This contract exchanges fixed amount of two Tokens, sending them to specified addresses
// All the data, i.e. addresses receiving the tokens (participants), Tokens and its amount for exchange supplied upon deploying the contract and cannot be changed later
// The moment for the exchange of tokens occurs when the second exchange participant sends exactly the number of tokens that were specified when the contract was deployied
// The deal can be canceled by any of participants (tokens are returned) at any time before actual exchange occured. Even if part of full amount of tokens where already transfered to this contract
// This contract can be reused assuming participants, tokens and its amount are not changed
// Contract does not check if participants can handle tokens, so it's your responsibility to provide participant addresses (externally or internally owned) that can handle tokens

pragma solidity ^0.4.24;

import "./NYXToken.sol";

contract ERC223Receiver {
    function tokenFallback(address _from, uint _value, bytes _data);
}

contract NyxTokenExchange is ERC223Receiver {	
    address owner;
    BasicToken tk1;
    BasicToken tk2;
    address tk_owner1;
    address tk_owner2;
    uint tk_amount1;
    uint tk_amount2;
    
    /*
    * Example data for constructor
    *
    * "0xdd870fa1b7c4700f2bd7f44238821c26f7392148","0x3643b7a9f6338115159a4d3a2cc678c99ad657aa",250000
    * ,"0x583031d1113ad414f02576bd6afabfb302140225","0xfc713aab72f97671badcb14669248c4e922fe2bb",310000
    */
    function NyxTokenExchange(address owner1, // participant 1
                                BasicToken token1, // token owned by participant 1
                                uint amount1, // amount of tokens of participant 1 for exchange
                                address owner2, // participant 2
                                BasicToken token2, // token owned by participant 2
                                uint amount2) { // amount of tokens of participant 2 for exchange
        owner = msg.sender;
        tk_owner1 = owner1;
        tk_owner2 = owner2;
        tk1 = token1;
        tk2 = token2;
        tk_amount1 = amount1;
        tk_amount2 = amount2;
    }
    
    function doExchange() onlyParticipants {
        tk1.transfer(tk_owner2, tk_amount1);
        tk2.transfer(tk_owner1, tk_amount2);
    }
    
    function doCancelExchange() onlyParticipants {
        tk1.transfer(tk_owner1, tk1.balanceOf(this));
        tk2.transfer(tk_owner2, tk2.balanceOf(this));
    }
    
    modifier onlyParticipants()
    {
        require(tx.origin == tk_owner1 || tx.origin == tk_owner2);
        _;
    }
    
    function tokenFallback(address _sender, uint _value, bytes _data) {
        
        if(tk2.balanceOf(this) == tk_amount2 && tk1.balanceOf(this) == tk_amount1)
            doExchange();
    }
}