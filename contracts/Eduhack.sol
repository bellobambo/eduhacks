// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract LMS {
    struct Question {
        string questionText;
        string[] options;
        uint8 correctOption;
    }

    struct Submission {
        address studentAddress;
        string studentName;
        string matricNumber;
        uint256 score;
        uint256 submissionTime;
    }

    struct Exam {
        uint256 examId;
        string examTitle;
        uint256 duration;
        uint256 startTime;
        uint256 courseId;
        address lecturer;
        string lecturerName;
        Question[] questions;
        Submission[] submissions;
        mapping(address => bool) hasSubmitted;
    }

    struct Course {
        uint256 courseId;
        string title;
        string description;
        address lecturer;
        string lecturerName;
        uint256 creationDate;
        uint256[] examIds;
        mapping(address => bool) enrolledStudents;
    }

    struct UserProfile {
        address walletAddress;
        string name;
        string matricNumber;
        bool isLecturer;
        string mainCourse;
        mapping(uint256 => bool) enrolledCourses;
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(string => address) public matricToAddress;

    mapping(uint256 => Course) public courses;
    uint256[] public courseIds;
    uint256 public courseCount;

    mapping(uint256 => Exam) public exams;
    uint256[] public examIds;
    uint256 public examCount;

    // Events
    event UserRegistered(
        address indexed user,
        string name,
        string matricNumber,
        bool isLecturer,
        string mainCourse
    );
    event CourseCreated(uint256 courseId, address lecturer, string title);
    event StudentEnrolled(uint256 indexed courseId, address student);
    event ExamCreated(uint256 examId, uint256 courseId, string title);
    event ExamSubmitted(address student, string matricNumber, uint256 score);

    // === USER ===
    function registerUser(
        string memory _name,
        string memory _matricNumber,
        bool _isLecturer,
        string memory _mainCourse
    ) public {
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
            require(
                bytes(_mainCourse).length > 0,
                "Course required for students"
            );
        }

        UserProfile storage profile = userProfiles[msg.sender];
        profile.walletAddress = msg.sender;
        profile.name = _name;
        profile.matricNumber = _isLecturer ? "" : _matricNumber;
        profile.isLecturer = _isLecturer;
        profile.mainCourse = _mainCourse; // Store course for both roles

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

    function deleteUser() public {
        UserProfile storage profile = userProfiles[msg.sender];
        require(profile.walletAddress != address(0), "User not registered");

        if (!profile.isLecturer && bytes(profile.matricNumber).length > 0) {
            delete matricToAddress[profile.matricNumber];
        }

        delete userProfiles[msg.sender];
    }

    function getUserProfile(
        address _user
    )
        external
        view
        returns (address, string memory, string memory, bool, string memory)
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

    // === COURSES ===
    function createCourse(
        string memory _title,
        string memory _description
    ) public {
        require(userProfiles[msg.sender].isLecturer, "Only lecturers allowed");

        uint256 courseId = courseCount++;
        Course storage newCourse = courses[courseId];
        newCourse.courseId = courseId;
        newCourse.title = _title;
        newCourse.description = _description;
        newCourse.lecturer = msg.sender;
        newCourse.lecturerName = userProfiles[msg.sender].name;
        newCourse.creationDate = block.timestamp;

        courseIds.push(courseId);

        emit CourseCreated(courseId, msg.sender, _title);
    }

    function getAllCourseIds() public view returns (uint256[] memory) {
        return courseIds;
    }

    function enrollInCourse(uint256 _courseId) public {
        UserProfile storage profile = userProfiles[msg.sender];
        require(!profile.isLecturer, "Lecturers can't enroll");
        require(_courseId < courseCount, "Invalid course");
        require(
            !courses[_courseId].enrolledStudents[msg.sender],
            "Already enrolled"
        );

        courses[_courseId].enrolledStudents[msg.sender] = true;
        profile.enrolledCourses[_courseId] = true;

        emit StudentEnrolled(_courseId, msg.sender);
    }

    function isStudentEnrolled(
        address _student,
        uint256 _courseId
    ) public view returns (bool) {
        return courses[_courseId].enrolledStudents[_student];
    }

    function getCourseExamIds(
        uint256 _courseId
    ) public view returns (uint256[] memory) {
        return courses[_courseId].examIds;
    }

    // === EXAMS ===
    function createExam(
        uint256 _courseId,
        string memory _examTitle,
        uint256 _duration
    ) public {
        Course storage course = courses[_courseId];
        require(course.lecturer == msg.sender, "Not course lecturer");

        uint256 examId = examCount++;
        Exam storage newExam = exams[examId];
        newExam.examId = examId;
        newExam.examTitle = _examTitle;
        newExam.duration = _duration;
        newExam.startTime = block.timestamp;
        newExam.courseId = _courseId;
        newExam.lecturer = msg.sender;
        newExam.lecturerName = course.lecturerName;

        course.examIds.push(examId);
        examIds.push(examId);

        emit ExamCreated(examId, _courseId, _examTitle);
    }

    function getAllExamIds() public view returns (uint256[] memory) {
        return examIds;
    }

    function addQuestion(
        uint256 _examId,
        string memory _questionText,
        string[] memory _options,
        uint8 _correctOption
    ) public {
        Exam storage exam = exams[_examId];
        require(exam.lecturer == msg.sender, "Not exam lecturer");
        exam.questions.push(Question(_questionText, _options, _correctOption));
    }

    function addQuestionsBatch(
        uint256 _examId,
        string[] memory _questionTexts,
        string[][] memory _options,
        uint8[] memory _correctOptions
    ) public {
        require(
            _questionTexts.length == _options.length &&
                _options.length == _correctOptions.length,
            "Array mismatch"
        );
        Exam storage exam = exams[_examId];
        require(exam.lecturer == msg.sender, "Not exam lecturer");

        for (uint i = 0; i < _questionTexts.length; i++) {
            exam.questions.push(
                Question(_questionTexts[i], _options[i], _correctOptions[i])
            );
        }
    }

    function submitAnswers(
        uint256 _examId,
        uint8[] memory _answers
    ) public returns (uint256) {
        Exam storage exam = exams[_examId];
        require(!exam.hasSubmitted[msg.sender], "Already submitted");
        require(
            block.timestamp <= exam.startTime + exam.duration,
            "Exam ended"
        );
        require(
            _answers.length == exam.questions.length,
            "Answer count mismatch"
        );

        UserProfile storage profile = userProfiles[msg.sender];
        require(!profile.isLecturer, "Only students");
        require(
            courses[exam.courseId].enrolledStudents[msg.sender],
            "Not enrolled"
        );

        uint256 score = 0;
        for (uint i = 0; i < _answers.length; i++) {
            if (_answers[i] == exam.questions[i].correctOption) {
                score++;
            }
        }

        exam.submissions.push(
            Submission(
                msg.sender,
                profile.name,
                profile.matricNumber,
                score,
                block.timestamp
            )
        );
        exam.hasSubmitted[msg.sender] = true;

        emit ExamSubmitted(msg.sender, profile.matricNumber, score);
        return score;
    }

    function getExamQuestions(
        uint256 _examId
    ) public view returns (Question[] memory) {
        return exams[_examId].questions;
    }

    function getExamSubmissions(
        uint256 _examId
    ) public view returns (Submission[] memory) {
        return exams[_examId].submissions;
    }
}
