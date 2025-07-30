// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Shared struct
struct Question {
    string questionText;
    string[] options;
    uint8 correctOption;
}

contract Exam {
    struct Submission {
        address studentAddress;
        string studentName;
        string matricNumber;
        uint256 score;
        uint256 submissionTime;
    }

    address public factory;
    address public lecturer;
    string public lecturerName;
    string public examTitle;
    uint256 public duration;
    uint256 public startTime;
    uint256 public courseId;

    Question[] public questions;
    Submission[] public submissions;
    mapping(address => bool) public hasSubmitted;

    event ExamSubmitted(
        address indexed student,
        string matricNumber,
        uint256 score
    );

    constructor(
        address _factory,
        address _lecturer,
        string memory _lecturerName,
        string memory _examTitle,
        uint256 _duration,
        uint256 _courseId
    ) {
        factory = _factory;
        lecturer = _lecturer;
        lecturerName = _lecturerName;
        examTitle = _examTitle;
        duration = _duration;
        startTime = block.timestamp;
        courseId = _courseId;
    }

    function addQuestion(
        string memory _questionText,
        string[] memory _options,
        uint8 _correctOption
    ) public {
        require(msg.sender == lecturer, "Only lecturer can add questions");
        questions.push(Question(_questionText, _options, _correctOption));
    }

    function addQuestionsBatch(
        string[] memory _questionTexts,
        string[][] memory _options,
        uint8[] memory _correctOptions
    ) public {
        require(msg.sender == lecturer, "Only lecturer can add questions");
        require(
            _questionTexts.length == _options.length &&
                _options.length == _correctOptions.length,
            "Array length mismatch"
        );

        for (uint256 i = 0; i < _questionTexts.length; i++) {
            questions.push(
                Question(_questionTexts[i], _options[i], _correctOptions[i])
            );
        }
    }

    function submitAnswers(uint8[] memory _answers) public returns (uint256) {
        require(!hasSubmitted[msg.sender], "Already submitted");
        require(block.timestamp <= startTime + duration, "Exam time has ended");
        require(_answers.length == questions.length, "Answer count mismatch");

        (
            address walletAddress,
            string memory name,
            string memory matricNumber,
            bool isLecturer,

        ) = CourseFactory(factory).getUserProfile(msg.sender);
        // walletAddress is currently unused but kept for potential future use

        require(!isLecturer, "Only students can submit");
        require(
            CourseFactory(factory).isStudentEnrolled(msg.sender, courseId),
            "Not enrolled"
        );

        uint256 score = 0;
        for (uint i = 0; i < questions.length; i++) {
            if (_answers[i] == questions[i].correctOption) {
                score++;
            }
        }

        submissions.push(
            Submission(msg.sender, name, matricNumber, score, block.timestamp)
        );
        hasSubmitted[msg.sender] = true;

        emit ExamSubmitted(msg.sender, matricNumber, score);
        return score;
    }

    function getQuestions() public view returns (Question[] memory) {
        return questions;
    }

    function getSubmissions() public view returns (Submission[] memory) {
        return submissions;
    }
}

contract CourseFactory {
    struct UserProfile {
        address walletAddress;
        string name;
        string matricNumber;
        bool isLecturer;
        string mainCourse;
        mapping(uint256 => bool) enrolledCourses;
    }

    struct Course {
        address lecturer;
        string lecturerName;
        string title;
        string description;
        uint256 creationDate;
        uint256 examCount;
        mapping(uint256 => address) exams;
        mapping(address => bool) enrolledStudents;
    }

    mapping(uint256 => Course) public courses;
    mapping(address => UserProfile) public userProfiles;
    mapping(string => address) public matricToAddress;
    uint256 public courseCount;

    event UserRegistered(
        address indexed userAddress,
        string name,
        string matricNumber,
        bool isLecturer,
        string mainCourse
    );
    event CourseCreated(
        uint256 indexed courseId,
        address lecturer,
        string title
    );
    event StudentEnrolled(
        uint256 indexed courseId,
        address studentAddress,
        string studentName,
        string matricNumber
    );
    event ExamCreated(
        uint256 indexed courseId,
        uint256 examId,
        address examAddress
    );

    function getUserProfile(
        address _user
    )
        public
        view
        returns (
            address walletAddress,
            string memory name,
            string memory matricNumber,
            bool isLecturer,
            string memory mainCourse
        )
    {
        UserProfile storage profile = userProfiles[_user];
        return (
            profile.walletAddress,
            profile.name,
            profile.matricNumber,
            profile.isLecturer,
            profile.mainCourse
        );
    }

    function isStudentEnrolled(
        address _student,
        uint256 _courseId
    ) public view returns (bool) {
        return courses[_courseId].enrolledStudents[_student];
    }

    function registerUser(
        string memory _name,
        string memory _matricNumber,
        bool _isLecturer,
        string memory _mainCourse
    ) public {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(
            userProfiles[msg.sender].walletAddress == address(0),
            "Already registered"
        );

        if (!_isLecturer) {
            require(bytes(_matricNumber).length > 0, "Matric required");
            require(
                matricToAddress[_matricNumber] == address(0),
                "Matric in use"
            );
        } else {
            require(
                bytes(_matricNumber).length == 0,
                "Lecturers don't need matric"
            );
            require(
                bytes(_mainCourse).length == 0,
                "Lecturers don't need main course"
            );
        }

        UserProfile storage profile = userProfiles[msg.sender];
        profile.walletAddress = msg.sender;
        profile.name = _name;
        profile.matricNumber = _isLecturer ? "" : _matricNumber;
        profile.isLecturer = _isLecturer;
        profile.mainCourse = _isLecturer ? "" : _mainCourse;

        if (!_isLecturer) {
            matricToAddress[_matricNumber] = msg.sender;
        }

        emit UserRegistered(
            msg.sender,
            _name,
            _matricNumber,
            _isLecturer,
            _mainCourse
        );
    }

    function createCourse(
        string memory _title,
        string memory _description
    ) public {
        require(userProfiles[msg.sender].isLecturer, "Only lecturers allowed");
        require(bytes(_title).length > 0, "Title required");

        courseCount++;
        Course storage c = courses[courseCount];
        c.lecturer = msg.sender;
        c.lecturerName = userProfiles[msg.sender].name;
        c.title = _title;
        c.description = _description;
        c.creationDate = block.timestamp;

        emit CourseCreated(courseCount, msg.sender, _title);
    }

    function enrollInCourse(uint256 _courseId) public {
        UserProfile storage profile = userProfiles[msg.sender];
        require(!profile.isLecturer, "Lecturers can't enroll");
        require(_courseId > 0 && _courseId <= courseCount, "Invalid course ID");
        require(
            !courses[_courseId].enrolledStudents[msg.sender],
            "Already enrolled"
        );
        require(bytes(profile.matricNumber).length > 0, "No matric");

        courses[_courseId].enrolledStudents[msg.sender] = true;
        profile.enrolledCourses[_courseId] = true;

        emit StudentEnrolled(
            _courseId,
            msg.sender,
            profile.name,
            profile.matricNumber
        );
    }

    function createExam(
        uint256 _courseId,
        string memory _examTitle,
        uint256 _duration
    ) public returns (address) {
        require(
            courses[_courseId].lecturer == msg.sender,
            "Not course lecturer"
        );
        require(bytes(_examTitle).length > 0, "Title required");

        Exam newExam = new Exam(
            address(this),
            msg.sender,
            userProfiles[msg.sender].name,
            _examTitle,
            _duration,
            _courseId
        );

        uint256 examId = courses[_courseId].examCount;
        courses[_courseId].exams[examId] = address(newExam);
        courses[_courseId].examCount++;

        emit ExamCreated(_courseId, examId, address(newExam));
        return address(newExam);
    }

    function getExamAddress(
        uint256 _courseId,
        uint256 _examId
    ) public view returns (address) {
        return courses[_courseId].exams[_examId];
    }
}
