//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
 
contract Qrate {
    using Counters for Counters.Counter;
    address public chairperson;
    Counters.Counter public totalQuestions;

    constructor(){
        chairperson = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == chairperson,
            "You are not authorized to perform this operation."
        );
        _;
    }
 
    enum QuestionStatus {
        PENDING,
        ACCEPTED,
        REJECTED
    }
 
    struct ModeratorStruct{
        string name;
        string subject;
        string proof;
        bool approved;
    }

    struct QuestionStruct{
        string questionString;
        string subject;
        string topic;
        string subTopic;
        uint256 upvotes;
        uint256 downvotes;
        address applicant;
        QuestionStatus status;
    }

    mapping(address=>ModeratorStruct) public moderators;
    mapping(uint256 => QuestionStruct) public questions;
    mapping(address => mapping(uint256=>bool)) public questionVoters;
    mapping(string => uint256) public threshold;
    mapping(string => uint256) public minVotes;

    event Moderator(address indexed moderatorAddress, ModeratorStruct moderator);
    event Question(uint256 indexed quesId, address sender, QuestionStruct question);
    event Subject(string subject);

    function setThresholdAndMinVotes(string memory _subject, uint256 _threshold, uint256 _minVotes) public onlyOwner{
        require(bytes(_subject).length > 0, "Subject cannot be empty");
        require(_threshold > 0, "Threshold cannot be 0");
        require(_minVotes > 0, "Minimum votes cannot be 0");
        threshold[_subject] = _threshold; 
        minVotes[_subject] = _minVotes;
        emit Subject(_subject);
    }

    function getThresholdAndMinVotes(string memory _subject) internal view returns(uint256, uint256){
        return (threshold[_subject], minVotes[_subject]);
    }

    function addQuestion(string memory _questionString, string memory _subject, string memory _topic, string memory _subTopic) public{
        require(bytes(_questionString).length > 0, "Question cannot be empty");
        require(bytes(_subTopic).length > 0, "Sub Topic cannot be empty");
        require(bytes(_subject).length > 0, "Subject cannot be empty");
        QuestionStruct storage q = questions[totalQuestions.current()];
        q.questionString = _questionString;
        q.subject = _subject;
        q.topic = _topic;
        q.subTopic = _subTopic;
        q.applicant = msg.sender;
        q.status = QuestionStatus.PENDING;  
        emit Question(totalQuestions.current(), address(0), q);
        totalQuestions.increment();
    }

    function updateQuestion(uint256 _id, bool _vote) public{
        ModeratorStruct memory m = moderators[msg.sender];
        QuestionStruct storage q = questions[_id];
        require(m.approved, "Not a chairperson approved moderator.");
        require((keccak256(bytes(m.subject)) == keccak256(bytes(q.subject))), "Not a moderator for the required subject");
        require(!questionVoters[msg.sender][_id], "Already Voted!");
        questionVoters[msg.sender][_id] = true;
        if(_vote)
            q.upvotes++;
        else
            q.downvotes++;
        (uint256 th, uint256 mv) = getThresholdAndMinVotes(q.subject);
        if(q.upvotes >= th && q.upvotes+q.downvotes >= mv)
            q.status = QuestionStatus.ACCEPTED;
        else if(q.downvotes >= th && q.upvotes+q.downvotes >= mv)
            q.status = QuestionStatus.REJECTED;
        emit Question(_id, msg.sender, q);
    }

    function applyAsModerator(string memory _name, string memory _subject, string memory _proof) public {
        require(bytes(_name).length > 0, "Question cannot be empty");
        require(bytes(_subject).length > 0, "Subject cannot be empty");
        ModeratorStruct storage m = moderators[msg.sender];
        m.name = _name;
        m.subject = _subject;
        m.proof = _proof;
        m.approved = false;
        emit Moderator(msg.sender, m);
    }

    function changeModeratorStatus(address _moderator) public onlyOwner{
        require(_moderator != address(0), "Moderator address cannot be empty");
        ModeratorStruct storage m = moderators[_moderator];
        require((keccak256(bytes(m.subject)) != keccak256(bytes(""))),"Not applied as a moderator");
        m.approved = !m.approved;
        emit Moderator(_moderator, m);
    }
}