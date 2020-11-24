pragma solidity >0.4.8 <= 0.7.0;
pragma experimental ABIEncoderV2;
 
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

 
contract IRV_Votingtoken {
    using SafeMath for uint256;
    address private owner;

    string private _name = "QVoting";
    string private _symbol = "QV";
    uint8 private _decimals = 0;
    uint8 private _totalSupply;
    
    
    uint256 private vote_waiting_time = 1 minutes;
    mapping(address => uint8) private _balances;
    mapping(bytes32 => bool) private proposals;
    mapping(bytes32 => uint256) proposalsEnd;


    struct votingCand {
        address[] candidates;
        address votee;
    }
    
    mapping(bytes32 => address[]) candidate_master;
    
    
    struct voteeInfo {
        address votee;
        mapping(bytes32 => bool) voted;
        mapping(bytes32 => votingCand) proposalcandidates;
    }  


    struct votingInfo {
        bytes32 proposal;
        uint256 ballotSize;
        uint256 totalVotes;
        bool active;
        address winner;
        mapping(uint256 => votingCand) ballot;
        mapping(address => uint8) AllCandiates_to_Votes;
    }

    mapping(bytes32 => votingInfo) results;
    mapping(address => voteeInfo) voteeDB;


    //Event when a new proposal is created
    event newProposal (
        address issuer,
        bytes32 proposal,
        uint256 endTime
    );

    //Event when an address votes on a proposal
    event voter(
        address votee,
        bytes32 proposal,
        votingCand voteType,
        uint256 timeVote
    );
       
    //Event when an proposal is out of time and has been checked.
    event voteResult(
        bytes32 proposal,
        address winner
    );

       

    constructor() public {
        owner = msg.sender;
    }

    modifier isProposal(bytes32 proposal) {
     require(proposals[proposal] == true);
     _;   
    }

    modifier isValidVote( bytes32 proposal, votingCand memory voters_choices) {
        require(candidate_master[proposal].length == voters_choices.candidates.length);
        for(uint i = 0; i < voters_choices.candidates.length; ++i) {

            bool candFound = false;
            for(uint j = 0; j < candidate_master[proposal].length; j++ ) {
                if(voters_choices.candidates[i] == candidate_master[proposal][j]) {
                   candFound = true; 
                }
            }
            require(candFound == true);
        }
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals of the token.
     * Note that since this is a voting token we do not want it to be divisible
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev The total number of tokens in circulation
     */
    function totalSupply() public view returns (uint8) {
        return _totalSupply;
    }

     /**
     * @param address_to_check The address to check
     * @dev Returns the balance of voting tokens of a given address
     */
    function getBalance(address address_to_check) public view returns(uint8) {
        return _balances[address_to_check];
    }

    /**
     * @param new_proposal The UID of other unique identifier for proposals, it MUST be unique
     * @param ballot_names The list of all addresses who are being voted on
     * @dev Creates a new proposal to be voted on
     */
    function createProposal(bytes32 new_proposal, address[] memory ballot_names) public {
        require(proposals[new_proposal] != true, "Already a proposal by this name");
        //Require that none of these are bad addresses needs a modifier
        proposals[new_proposal] = true;
        uint256 endTime = now + vote_waiting_time;
        proposalsEnd[new_proposal] = endTime;

        candidate_master[new_proposal] = ballot_names; // The list of candidates on the ballot
        
        //mapping(address => uint8) storage temp_votes_and_candidates;
        

       
        results[new_proposal] = votingInfo(new_proposal, 0,  0, false, address(0) );
   
        for(uint i = 0; i < ballot_names.length; ++i) {
            results[new_proposal].AllCandiates_to_Votes[ballot_names[i]] = 0;
        }
        emit newProposal(
            msg.sender, new_proposal, endTime );
        }


     /**
     * @param proposal A valid proposal that has been created, member function checks proposal validity
     * @dev Checks the outcome of a proposal, for this to be sucessful the time at which this function is called
     * MUST be after the end Time of the voting. It is purposley not possible to check a proposal midvote.
     */
    function checkProposal(bytes32 proposal) isProposal(proposal) public returns(address winner){
        require(voteeDB[msg.sender].voted[proposal] == true, "You must of voted to check proposal");
        require(now > proposalsEnd[proposal]);
        require(results[proposal].totalVotes > 0);
        uint256 total = ((results[proposal].totalVotes / 2) + 1);
        uint256 minCand_votes = results[proposal].AllCandiates_to_Votes[candidate_master[proposal][0]];
        address min;
        uint256 min_index;
         //CHECKS IF THERE IS A MAJORITY WINNER
        for(uint256 i = 0; i < candidate_master[proposal].length; ++i) {
            if(results[proposal].AllCandiates_to_Votes[candidate_master[proposal][i]] >= total) {
                results[proposal].active = false;
                results[proposal].winner = candidate_master[proposal][i]; //FIXME who passed
                emit voteResult(proposal, candidate_master[proposal][i] );
                return candidate_master[proposal][i];
            }
            if(minCand_votes > results[proposal].AllCandiates_to_Votes[candidate_master[proposal][i]] ) {
                //If there is a tie on minCand and there is no majority winner TODO
                minCand_votes = results[proposal].AllCandiates_to_Votes[candidate_master[proposal][i]];
                min = candidate_master[proposal][i];
                min_index = i;
                }
        }
        //CONTINUES TO REMOVE SMALLEST candidates
       address[] storage remaining = candidate_master[proposal];
       uint8 iter = 0;
       while(true) {
           for(uint256 i = 0; i < results[proposal].ballotSize; ++i ) {
               if(results[proposal].ballot[i].candidates[iter] == min) {
                   results[proposal].AllCandiates_to_Votes[results[proposal].ballot[i].candidates[iter + 1]] += 1;
               }
           } //REMOVE candidate
        remaining[min_index] = remaining[remaining.length - 1];
        delete remaining[remaining.length -1];
        remaining.length--;
        minCand_votes = results[proposal].AllCandiates_to_Votes[remaining[0]];
        for(uint i = 0; i < remaining.length; ++i) {
            if(results[proposal].AllCandiates_to_Votes[remaining[i]] >= total) {
                results[proposal].active = false;
                results[proposal].winner = remaining[i]; //FIXME who passed
                emit voteResult(proposal, remaining[i] );
                return remaining[i];
            }
            if(minCand_votes > results[proposal].AllCandiates_to_Votes[remaining[i]] ) {
                //If there is a tie on minCand and there is no majority winner TODO
                minCand_votes = results[proposal].AllCandiates_to_Votes[remaining[i]];
                min = remaining[i];
                min_index = i;
                }
        }
       
        ++iter;
       } //WHILE

    } // FUNCTION

     /**
     * @param proposal A valid proposal that has been created, member function checks proposal validity
     * @param voters_choices A structure that has the voters choices and the name of the voter
     * @dev Allows an given address to  vote on a proposal given by the proposal name, and their candidate choices
     * Each address can only vote ONCE
     */
    function vote(bytes32 proposal, votingCand memory voters_choices ) isProposal(proposal) isValidVote(proposal,voters_choices) public {
        require(getBalance(msg.sender) >= 1, "You can only vote with as many votes as you currently possess");
        require(now <  proposalsEnd[proposal], "It is past time of voting");
        require(voteeDB[msg.sender].voted[proposal] != true, "You cannot vote twice");
        uint256 votingTime = now;
        //uint8 weight = sqrt(votes);
        burn(msg.sender, 1);
        results[proposal].ballot[results[proposal].ballotSize] = voters_choices;
        results[proposal].ballotSize++;
        address first_choice = voters_choices.candidates[0];
        results[proposal].AllCandiates_to_Votes[first_choice] += 1;
        results[proposal].totalVotes += 1;
        voteeDB[msg.sender].voted[proposal] = true;
        voteeDB[msg.sender].proposalcandidates[proposal] = voters_choices;

        emit voter (msg.sender, proposal, voters_choices, votingTime); 
        
    }

   

     /**
     * @param address_to_add Address to give votes too
     * @param votes the given amount of votes to give to a certain address
     * @dev Currently this is allowing the owner to send this, however the process of this will most often change when 
     * connected to a dao, it could even be set up automatically to disperse at a given time.
     */
    function mint(address address_to_add, uint8 votes) public isOwner() {
        _totalSupply += votes;
        _balances[address_to_add] += votes;
    } 

    /**
     * @param address_to_burn Address to burn votes from
     * @param votes the given amount of votes to burn to a certain address
     * @dev Internal function to burn votes after an address votes on an issue.
     */
    function burn(address address_to_burn, uint8 votes) internal {
        require(getBalance(address_to_burn) >= votes, "Cannot burn more votes then address owns");
        _totalSupply -= votes;
        _balances[address_to_burn] -= votes;
    }

    
}

