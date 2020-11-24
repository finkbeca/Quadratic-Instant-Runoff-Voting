const IRV = artifacts.require("IRV_Votingtoken");
const { time} = require('@openzeppelin/test-helpers');
const { assert } = require('console');

contract ("IRV Tests", async accounts => {
    it("deployment", async () => {
        let contract = await IRV.deployed();
        let blank = 0x0000000000000000000000000000000000000000;
        assert(blank != contract.constructor.class_defaults.from);
      });
      it("proposal_test", async () => {
          let contract = await IRV.deployed();
          assert("dec", await contract.decimals() == 0);
          assert("name", await contract.name() == 'QVoting');
          assert("symbol", await contract.symbol() == 'QV');
  
          await contract.mint(accounts[3], 4);
          await contract.mint(accounts[1], 1);
          await contract.mint(accounts[4], 1);
          await contract.mint(accounts[5], 1);
          assert("total", await contract.totalSupply() == 7);
          assert(await contract.getBalance(accounts[3]) == 4);
          assert(await contract.getBalance(accounts[1]) == 1);
          console.log("Test", await contract.getBalance(accounts[1]))
          let cand = [accounts[0], accounts[2]];

          await contract.createProposal(web3.utils.asciiToHex("1"), cand);

          var array = [];
          array.push(accounts[0]);
          array.push(accounts[2]);
          var votingCand = {};
          votingCand["tmp"] = {
            "candidates": array,
            "votee": accounts[1]
          };
          await contract.vote(web3.utils.asciiToHex("1"), votingCand.tmp, {from: accounts[1]});
          assert("test", await contract.totalSupply() == 6);
          await contract.vote(web3.utils.asciiToHex("1"), votingCand.tmp, {from: accounts[3]});
          await time.increase(120);
          let account = await contract.checkProposal(web3.utils.asciiToHex("1"), {from: accounts[1]});
          console.log("Test", account);
          assert(account  == accounts[0]);
          /*

          
          await contract.vote(web3.utils.asciiToHex("1"), 1, true, {from: accounts[1]});
          assert(await contract.totalSupply() == 6);
          await contract.vote(web3.utils.asciiToHex("1"), 4, false, {from: accounts[2]});
          assert(await contract.totalSupply() == 2);
          await time.increase(120);
          assert(await contract.checkProposal(web3.utils.asciiToHex("1"), {from: accounts[1]}) == true);
            */
      });    
      
      it("proposal_test_2", async () => {
        let contract = await IRV.deployed();
        await contract.mint(accounts[3], 1);
          await contract.mint(accounts[1], 1);
          await contract.mint(accounts[4], 1);
          await contract.mint(accounts[5], 1);
          await contract.mint(accounts[6], 1);
          await contract.mint(accounts[7], 1);
          await contract.mint(accounts[8], 1);
          assert(await contract.totalSupply() == 7);
          assert(await contract.getBalance(accounts[3]) == 1);
          assert(await contract.getBalance(accounts[1]) == 1);
          let cand = [accounts[0], accounts[2], accounts[9]];
          await contract.createProposal(web3.utils.asciiToHex("2"), cand);


          var array = [];
          array.push(accounts[0]);
          array.push(accounts[2]);
          array.push(accounts[9]);

          var array_1 = [];
          array_1.push(accounts[2]);
          array_1.push(accounts[0]);
          array_1.push(accounts[9]);

          var array_2 = [];
          array_2.push(accounts[9]);
          array_2.push(accounts[2]);
          array_2.push(accounts[0]);
          

          var votingCand_0 = {};
          votingCand_0["tmp"] = {
            "candidates": array,
            "votee": accounts[1] // This is purely meta data and may be beneficial dependent on dapp structure 
          };

          var votingCand_2 = {};
          votingCand_2["tmp"] = {
            "candidates": array_1,
            "votee": accounts[1]
          };

          var votingCand_9 = {};
          votingCand_9["tmp"] = {
            "candidates": array_2,
            "votee": accounts[1]
          };

          await contract.vote(web3.utils.asciiToHex("2"), votingCand_0.tmp, {from: accounts[1]});
          await contract.vote(web3.utils.asciiToHex("2"), votingCand_0.tmp, {from: accounts[4]});
          await contract.vote(web3.utils.asciiToHex("2"), votingCand_0.tmp, {from: accounts[3]});
          //VOTES FOR 0

          await contract.vote(web3.utils.asciiToHex("2"), votingCand_2.tmp, {from: accounts[5]});
          await contract.vote(web3.utils.asciiToHex("2"), votingCand_2.tmp, {from: accounts[6]});
          await contract.vote(web3.utils.asciiToHex("2"), votingCand_2.tmp, {from: accounts[7]});
          // VOTES FOR 2
          assert(await contract.totalSupply() == 1);

          await contract.vote(web3.utils.asciiToHex("2"), votingCand_9.tmp, {from: accounts[8]});
          await time.increase(120);
          assert(await contract.checkProposal(web3.utils.asciiToHex("2"), {from: accounts[1]}) == accounts[2]);
          
          

      });
});