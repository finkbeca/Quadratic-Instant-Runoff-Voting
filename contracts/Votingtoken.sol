pragma solidity >0.4.8 <= 0.7.0;
 
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

 
contract Votingtoken {
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

    struct voteeInfo {
        address votee;
        mapping(bytes32 => bool) voted;
        mapping(bytes32 => uint256) voteWeight;
        mapping(bytes32 => bool) proposalYesVote;
    }  


    struct votingInfo {
        bytes32 proposal;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalVotes;
        bool active;
        bool passed;
    }

    mapping(bytes32 => votingInfo) results;
    mapping(address => voteeInfo) voteeDB;

    constructor() public {
        owner = msg.sender;
    }

    modifier isProposal(bytes32 proposal) {
     require(proposals[proposal] == true);
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

    function getBalance(address address_to_check) public view returns(uint8) {
        return _balances[address_to_check];
    }

    function createProposal(bytes32 new_proposal) public {
        proposals[new_proposal] = true;
        proposalsEnd[new_proposal] = now + vote_waiting_time;

        votingInfo memory new_prop = votingInfo( {
            proposal: new_proposal,
            yesVotes: 0,
            noVotes: 0,
            totalVotes: 0,
            active: false,
            passed: false
        });
        results[new_proposal] = new_prop;

        }


    function checkProposal(bytes32 proposal) isProposal(proposal) public returns(bool truth){
        require(voteeDB[msg.sender].voted[proposal] == true, "You must of voted to check proposal");
        require(now > proposalsEnd[proposal]);
        if(results[proposal].yesVotes > results[proposal].noVotes) {
            results[proposal].active = false;
            results[proposal].passed = true;
            //Emit vote outcome
            return true;
        }

        else {
            results[proposal].active = false;
            results[proposal].passed = false;
            return false;
        }
    }

    function vote(bytes32 proposal, uint8 votes, bool yesVote) isProposal(proposal) public {
        require(getBalance(msg.sender) >= votes, "You can only vote with as many votes as you currently possess");
        require(now <  proposalsEnd[proposal], "It is past time of voting");
        require(voteeDB[msg.sender].voted[proposal] != true, "You cannot vote twice");
        
        uint8 weight = sqrt(votes);
        burn(msg.sender, votes);
        if(yesVote) {
            results[proposal].yesVotes += weight;
        }
        else {
            results[proposal].noVotes += weight;
        }
        results[proposal].totalVotes += weight;
        voteeDB[msg.sender].voted[proposal] = true;
        voteeDB[msg.sender].voteWeight[proposal] = weight;
        voteeDB[msg.sender].proposalYesVote[proposal] = yesVote;
        
    }
    function sqrt(uint8 num) public returns(uint8 root) {
        uint8 z = (num + 1) / 2;
        uint8 y = num;
        while (z < y) {
            y = z;
            z = (num / z + z) / 2;
        }
        return y;
    }

    function mint(address address_to_add, uint8 votes) public isOwner() {
        _totalSupply += votes;
        _balances[address_to_add] += votes;
    } 

    function burn(address address_to_burn, uint8 votes) internal {
        require(getBalance(address_to_burn) >= votes, "Cannot burn more votes then address owns");
        _totalSupply -= votes;
        _balances[address_to_burn] -= votes;
    }

    
}

