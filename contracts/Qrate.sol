//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";

/// Qrate Main Contract
contract Qrate {
    using Counters for Counters.Counter;

    Counters.Counter public totalQuestions;

    address public chairperson;
    enum QuestionStatus {
        PENDING,
        ACCEPTED,
        REJECTED
    }

    event Question(QuestionStruct question);
    event Moderator(address moderatorAddress, string subject, bool approved);

    struct QuestionStruct {
        uint256 mainId;
        uint256 id;
        string question_string;
        string subject;
        string topic;
        string subTopic;
        uint256 upvotes;
        uint256 downvotes;
        address applicant;
        QuestionStatus status;
        uint256 incentives;
    }

    mapping(string => mapping(address => bool)) public moderators; // subject -> moderator_address -> approved
    mapping(string => uint256) public moderatorCount; // subject -> count
    mapping(string => QuestionStruct[]) public questions; // subject -> questions[]
    mapping(string => mapping(uint256 => address[])) public questionVoters; // question_id -> moderators_who_have_voted[]

    function getQuestionVoters(string memory _subject, uint256 _id)
        public
        view
        returns (address[] memory)
    {
        return questionVoters[_subject][_id];
    }

    mapping(string => mapping(uint256 => mapping(address => bool)))
        public questionVoted; // question_id -> moderator_address -> vote_status(weather_voted_or_not)
    mapping(string => uint256) public threshold; // subject -> min_number_of_votes
    mapping(string => uint256) public minVotes;

    mapping(string => mapping(uint256 => bool)) public questionToCheck; // subject -> question_id -> to_check_or_not
    mapping(string => uint256[]) public questionIdsToCheck; // subject -> questions_to_check

    function getQuestionIdsToCheck(string memory _subject)
        public
        view
        returns (uint256[] memory)
    {
        return questionIdsToCheck[_subject];
    }

    mapping(string => Counters.Counter) private counters; // subject -> counter

    constructor() {
        chairperson = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == chairperson,
            "You are not authorized to perform this operation."
        );
        _;
    }

    /**
     * Submit Application to become a moderator
     * @param _subject subject to apply for
     */
    function applyAsModerator(string memory _subject) public {
        moderators[_subject][msg.sender] = false;
        emit Moderator(msg.sender, _subject, false);
    }

    /**
     * Approve Moderator to make them eligible to vote on questions
     * ! only deployer can run this function
     * @param _address moderator_address
     * @param _subject subject to approve for
     */
    function approveModerator(address _address, string memory _subject)
        public
        onlyOwner
    {
        require(!moderators[_subject][_address], "Already A Moderator");
        if (!moderators[_subject][_address]) {
            moderators[_subject][_address] = true;
            moderatorCount[_subject]++;
            emit Moderator(_address, _subject, true);
        }
    }

    /**
     * Add/Create Question for a specific subject
     */
    function addQuestion(
        string memory _question_string,
        string memory _subject,
        string memory _topic,
        string memory _subTopic
    ) public {
        QuestionStruct memory q = QuestionStruct({
            mainId: totalQuestions.current(),
            id: counters[_subject].current(),
            question_string: _question_string,
            subject: _subject,
            topic: _topic,
            subTopic: _subTopic,
            upvotes: 0,
            downvotes: 0,
            applicant: msg.sender,
            status: QuestionStatus.PENDING,
            incentives: 0
        });
        questions[_subject].push(q);
        emit Question(q);
        counters[_subject].increment();
        totalQuestions.increment();
    }

    function getQuestions(string memory _subject)
        public
        view
        returns (QuestionStruct[] memory)
    {
        return questions[_subject];
    }

    function updateQuestion(
        uint256 _id,
        string memory _subject,
        bool _vote
    ) public {
        require(
            moderators[_subject][msg.sender],
            "Not an authorized moderator"
        );
        require(!questionVoted[_subject][_id][msg.sender], "Already Voted");
        QuestionStruct storage q = questions[_subject][_id];
        if (_vote) q.upvotes = q.upvotes + 1;
        else q.downvotes = q.downvotes + 1;
        questionVoted[_subject][_id][msg.sender] = true;
        questionVoters[_subject][_id].push(msg.sender);
        emit Question(q);
        if (!questionToCheck[_subject][_id]) {
            questionToCheck[_subject][_id] = true;
            questionIdsToCheck[_subject].push(_id);
        }
    }

    function setThreshold(string memory _subject, uint256 _threshold)
        public
        onlyOwner
    {
        threshold[_subject] = _threshold;
    }

    function setMinVotes(string memory _subject, uint256 _minVotes)
        public
        onlyOwner
    {
        minVotes[_subject] = _minVotes;
    }

    function checkApproval(uint256 _id, string memory _subject) internal {
        QuestionStruct storage q = questions[_subject][_id];
        uint256 minimum_needed_votes = minVotes[_subject];
        // check weather total votes are
        if ((q.upvotes + q.downvotes) < minimum_needed_votes) {
            return;
        }
        if (q.upvotes > threshold[_subject]) q.status = QuestionStatus.ACCEPTED;
        else if (q.downvotes > threshold[_subject])
            q.status = QuestionStatus.REJECTED;
    }

    function changeQuestionStatus(string memory _subject) public {
        require(minVotes[_subject] > 0, "No Minimum Number of Votes Set.");
        for (uint256 i = 0; i < questionIdsToCheck[_subject].length; i++) {
            uint256 questionId = questionIdsToCheck[_subject][i]; // question ID to check
            checkApproval(questionId, _subject); // approve if okay else no
            questionToCheck[_subject][questionId] = false; // dont check next time
        }
        delete questionIdsToCheck[_subject];
    }

    fallback() external {}

    receive() external payable {
        //emit AmountCredit(msg.sender, msg.value);
    }
}
