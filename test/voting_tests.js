const { time} = require('@openzeppelin/test-helpers');
const { assert } = require('console');

const votingToken = artifacts.require("Votingtoken");


contract("VotingToken Tests", async (accounts) => {
   
    it("deployment", async () => {
      let contract = await votingToken.deployed();
      let blank = 0x0000000000000000000000000000000000000000;
      assert(blank != contract.constructor.class_defaults.from);
    });
    it("proposal_test", async () => {
        let contract = await votingToken.deployed();
        assert(await contract.decimals() == 0);
        assert(await contract.name() == 'QVoting');
        assert(await contract.symbol() == 'QV');

        await contract.mint(accounts[2], 5);
        await contract.mint(accounts[1], 2);
        assert(await contract.totalSupply() == 7);
        assert(await contract.getBalance(accounts[2]) == 5);
        assert(await contract.getBalance(accounts[1]) == 2);
       
        await contract.createProposal(web3.utils.asciiToHex("1"));
        await contract.vote(web3.utils.asciiToHex("1"), 1, true, {from: accounts[1]});
        assert(await contract.totalSupply() == 6);
        await contract.vote(web3.utils.asciiToHex("1"), 4, false, {from: accounts[2]});
        assert(await contract.totalSupply() == 2);
        await time.increase(120);
        assert(await contract.checkProposal(web3.utils.asciiToHex("1"), {from: accounts[1]}) == true);

    });     
})  