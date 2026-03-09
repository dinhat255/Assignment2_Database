-- Tạo database ElearningDB
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'ElearningDB')
BEGIN
    ALTER DATABASE ElearningDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ElearningDB;
END
GO

CREATE DATABASE ElearningDB;
GO

USE ElearningDB;
GO
CREATE TABLE ANSWER (
    -- 1. Hai cột này đóng vai trò là KHÓA NGOẠI (tham chiếu về bảng Câu hỏi)
    TestID              CHAR(10)        NOT NULL,
    QuestionNo          INT             NOT NULL,   -- Tương ứng với "STT câu hỏi" trong lược đồ

    -- 2. Cột này xác định thứ tự câu trả lời (A, B, C, D...)
    AnswerNo            INT             NOT NULL,   -- STT câu trả lời

    -- 3. Thông tin câu trả lời
    AnswerContent       NVARCHAR(MAX)   NOT NULL,   -- Nội dung
    IsCorrect           BIT             NOT NULL DEFAULT 0, -- 1 là Đúng, 0 là Sai

    -- 4. THIẾT LẬP KHÓA CHÍNH (Gồm 3 cột)
    -- Để đảm bảo trong 1 bài test, tại câu hỏi số X, không có 2 câu trả lời cùng số thứ tự Y
    PRIMARY KEY (TestID, QuestionNo, AnswerNo),

    -- 5. THIẾT LẬP KHÓA NGOẠI (Composite Foreign Key)
    -- Tham chiếu cả cặp (TestID, QuestionNo) về bảng cha TestQuestion
    -- CONSTRAINT FK_Answer_Question FOREIGN KEY (TestID, QuestionNo) 
    --     REFERENCES Question(TestID, QuestionNo)
    --     ON DELETE CASCADE -- Tùy chọn: Xóa câu hỏi thì xóa luôn câu trả lời
);
CREATE TABLE CHAPTER (
    ChapterID               CHAR(10)      PRIMARY KEY,                -- Ma so chuong            
    CourseID                CHAR(10)      NOT NULL,                            -- Ma so Khoa Hoc    FOREIGN KEY
    ChapterTitle            NVARCHAR(200) NOT NULL,
    ChapterOrder            INT           NOT NULL CHECK (ChapterOrder > 0),
    ChapterDescription      NVARCHAR(MAX)
    
);

-- DROP TABLE CHAPTER;
CREATE TABLE COMMENTS (
    UserID				CHAR(10)       NOT NULL,            -- Foreign Key references to UserID in UserTable table
    CreatedAt           DATETIME       NOT NULL DEFAULT GETDATE(),
    Content             NVARCHAR(MAX)  NOT NULL,
    ReplyCount          INT            NOT NULL DEFAULT 0   CHECK (ReplyCount >= 0),

    ReplyUserID			CHAR(10)       NULL,                -- Foreign Key references to UserID in COMMENTS table
    ReplyCreatedAt      DATETIME       NULL,                -- Foreign Key references to CreatedAt in COMMENTS table

    PostID              CHAR(10)       NULL,                -- Foreign Key references to PostID in POST table
    CourseID            CHAR(10)       NULL,                -- Foreign Key references to CourseID in Course table

	PRIMARY KEY (UserID, CreatedAt)
);


CREATE TABLE COURSE_ENROLLMENT (
    UserID          CHAR(10)    NOT NULL, 
    CourseID        CHAR(10)    NOT NULL,
    EnrollmentDate  DATETIME    DEFAULT GETDATE(),      -- automaticly get datetime

    PRIMARY KEY (UserID, CourseID)
);
CREATE TABLE COURSE_RATING ( 
    UserID          CHAR(10)    NOT NULL, 
    CourseID        CHAR(10)     NOT NULL,
    RatingValue     INT         CHECK (RatingValue >= 1 AND RatingValue <= 5), -- Điểm đánh giá (Ví dụ: từ 1 đến 5)
    
    PRIMARY KEY (UserID, CourseID)
);
CREATE TABLE COURSE (
    CourseID            CHAR(10)        PRIMARY KEY,            -- Đã sửa từ 5 lên 10
    CourseName          NVARCHAR(255)   NOT NULL,               -- Đã sửa thành NVARCHAR
    CourseState         NVARCHAR(50)    DEFAULT N'Sắp ra mắt',  -- Đã sửa thành NVARCHAR (ví dụ: 'Đang mở', 'Đã đóng')
    TeacherID           CHAR(10)        NOT NULL,               -- Foreign Key references to TeacherID in Teacher table
    
    TotalDuration       DECIMAL(10, 2)  DEFAULT 0   CHECK (TotalDuration >= 0), 
    NumTests            INT             DEFAULT 0   CHECK (NumTests >= 0), 
    NumTheoryLessons    INT             DEFAULT 0   CHECK (NumTheoryLessons >= 0), 
    NumExercises        INT             DEFAULT 0   CHECK (NumExercises >= 0),
    NumVideos           INT             DEFAULT 0   CHECK (NumVideos >= 0),
    AverageRating       DECIMAL(2, 1)   DEFAULT 0   CHECK (AverageRating >= 0.0 AND AverageRating <= 5.0),
    NumRatings          INT             DEFAULT 0   CHECK (NumRatings >= 0),
    NumStudents         INT             DEFAULT 0   CHECK (NumStudents >= 0), 

    -- Ràng buộc Unique cho tên khóa học
    CONSTRAINT UQ_CourseName UNIQUE(CourseName)
);

-- DROP TABLE COURSE;

CREATE TABLE EXERCISE_ATTEMPT (
    -- 1. Cột đếm số tự động (Dùng IDENTITY)
    -- Cột này chỉ dùng để đếm, không cần hiển thị ra ngoài nếu không muốn
    AutoID INT IDENTITY(1,1) NOT NULL,

    -- 2. Cột Khóa chính có tiền tố (COMPUTED COLUMN)
    -- Công thức: 'ATT' + Chuỗi số 0 đệm thêm + Số AutoID (cắt lấy 5 ký tự cuối)
    -- Kết quả sẽ là: ATT00001, ATT00002...
    AttemptID AS ('ATT' + RIGHT('00000' + CAST(AutoID AS VARCHAR(10)), 5)) PERSISTED,


    UserID              CHAR(10)        NOT NULL,     -- Foreign Key
    ExerciseID          CHAR(10)        NOT NULL,     -- Foreign Key
    StartTime           DATETIME        NOT NULL DEFAULT GETDATE(),
    SubmitTime          DATETIME,       
    Score               DECIMAL(5, 2)   CHECK (Score >= 0 AND Score <= 100),

    -- Định nghĩa AttemptID làm KHÓA CHÍNH
    CONSTRAINT PK_ExerciseAttempt PRIMARY KEY (AttemptID),

    -- Ràng buộc logic
    CONSTRAINT CK_SubmitTime CHECK (SubmitTime >= StartTime)
);

-- DROP TABLE EXERCISE_ATTEMPT;
CREATE TABLE EXERCISE (
    ExerciseID          CHAR(10)        NOT NULL PRIMARY KEY,
    ChapterID           CHAR(10)        NOT NULL,       -- Foreign Key
    Title               NVARCHAR(200)   NOT NULL,
    ExDescription       NVARCHAR(MAX)   NOT NULL,
    SampleAnswer        NVARCHAR(MAX)   NOT NULL,
    MinPassingScore     INT             NOT NULL CHECK (MinPassingScore >= 0 AND MinPassingScore <= 100),
    -- MaxScore            INT            NOT NULL CHECK (MaxScore >= 0 AND MaxScore <= 100),

    -- CONSTRAINT FK_Exercise_Chapter FOREIGN KEY (ChapterID) REFERENCES dbo.CHAPTER(ChapterID),
    -- CONSTRAINT CHK_Exercise_Score CHECK (MaxScore >= MinPassingScore)
);
CREATE TABLE POSTS (
    PostID        CHAR(10)        PRIMARY KEY,
    Title         NVARCHAR(200)   NOT NULL,
    Content       NVARCHAR(MAX)   NOT NULL,
    CreatedAt     DATETIME        NOT NULL  DEFAULT GETDATE(),
    UserID        CHAR(10)        NOT NULL        -- Foreign Key references to UserID in UserTable table
);
CREATE TABLE PRACTICES (
    PracticeID      CHAR(10)        PRIMARY KEY,
    Title           NVARCHAR(200)   NOT NULL,
    Difficulty      NVARCHAR(50)    NOT NULL,
    Content         NVARCHAR(MAX)   NOT NULL,
    TeacherID       CHAR(10)        NOT NULL      -- Foreign Key references to TeacherID in Teacher table
);
CREATE TABLE PRACTICE_ATTEMPT_INFO (
-- Cột đếm tự động (ẩn)
    AutoID              INT IDENTITY(1,1) NOT NULL,

    -- Cột Khóa chính tính toán: PRA00001, PRA00002...
    PracticeAttemptID   AS ('PRA' + RIGHT('00000' + CAST(AutoID AS VARCHAR(10)), 5)) PERSISTED,

    UserID              CHAR(10)        NOT NULL, 
    PracticeID          CHAR(10)        NOT NULL, 
    
    StartTime           DATETIME        NOT NULL DEFAULT GETDATE(),
    SubmitTime          DATETIME,       -- NULL nếu chưa nộp
    Score               INT             CHECK (Score >= 0 AND Score <= 100), -- Điểm số
    
    -- Thiết lập Khóa chính
    CONSTRAINT PK_PracticeAttempt PRIMARY KEY (PracticeAttemptID),

    -- Ràng buộc logic
    CONSTRAINT CK_PracticeAttempt_Time CHECK (SubmitTime >= StartTime)
);
CREATE TABLE QUESTION (
	TestID              CHAR(10)        NOT NULL,       -- Một phần của khóa chính
    QuestionNo          INT             NOT NULL,       -- STT (Một phần của khóa chính)
    
    QuestionContent     NVARCHAR(MAX)   NOT NULL,       -- Nội dung
    Score               INT             DEFAULT 0 CHECK (Score >= 0), -- Số điểm của câu này
    
    -- Thiết lập KHÓA CHÍNH PHỨC HỢP (Composite Primary Key)
    PRIMARY KEY (TestID, QuestionNo)
    
    -- Thiết lập khóa ngoại tham chiếu về Test
    -- CONSTRAINT FK_Question_Test FOREIGN KEY (TestID) REFERENCES Test(TestID)
    --     ON DELETE CASCADE -- Nếu xóa bài kiểm tra, xóa luôn câu hỏi
);
CREATE TABLE TEACHER_EDUCATION (
    EduID               INT             PRIMARY KEY IDENTITY(1,1),  -- Khóa thay thế tự tăng
    TeacherID           CHAR(10)        NOT NULL,    -- Cột này sẽ tham chiếu về GiaoVien
    Degree              NVARCHAR(50)    NOT NULL,           -- Ví dụ: Cử nhân, Thạc sĩ
    Major               NVARCHAR(100)   NOT NULL,      -- Ví dụ: Công nghệ thông tin
    School              NVARCHAR(100)   NOT NULL,           -- Tên trường
    StartTime           DATE,
    EndTime             DATE,

    CONSTRAINT CK_Edu_Time CHECK (EndTime > StartTime)
);

CREATE TABLE TEACHER (
    TeacherID  CHAR(10)    PRIMARY KEY
);
CREATE TABLE TEST_ATTEMPT_RECORDS (
-- Cột đếm số tự động (ẩn)
    AutoID INT IDENTITY(1,1) NOT NULL,

    -- Cột Khóa chính tính toán: TST00001, TST00002...
    TestAttemptID AS ('TST' + RIGHT('00000' + CAST(AutoID AS VARCHAR(10)), 5)) PERSISTED,

    UserID              CHAR(10)        NOT NULL, 
    TestID              CHAR(10)        NOT NULL, 
    
    StartTime           DATETIME        NOT NULL DEFAULT GETDATE(),
    SubmitTime          DATETIME,       -- NULL nếu chưa nộp
    Score               DECIMAL(5, 2)   CHECK (Score >= 0 AND Score <= 100), -- Điểm số
    
    CONSTRAINT PK_TestAttempt PRIMARY KEY (TestAttemptID),
    
    -- Ràng buộc logic: Ngày nộp phải sau ngày bắt đầu
    CONSTRAINT CK_TestAttempt_Time CHECK (SubmitTime >= StartTime)
);
CREATE TABLE TEST (
	TestID			CHAR (10)		PRIMARY KEY,
	TestName		NVARCHAR(200)	NOT NULL,
	TestDuration	INT				NOT NULL	CHECK (TestDuration > 0),
	ScoreToPass		INT				DEFAULT 0	CHECK (ScoreToPass >= 0),
	TotalScore		INT				DEFAULT 0	CHECK (TotalScore >= 0),
	ChapterID		CHAR (10)		NOT NULL		-- Foreign Key to Chapter Table
);
CREATE TABLE THEORY_LESSON (
    TheoryLessonID  CHAR(10)      NOT NULL PRIMARY KEY,
    ChapterID       CHAR(10)      NOT NULL,                 -- FOREIGN KEY
    Title           NVARCHAR(200) NOT NULL,
    Content         NVARCHAR(MAX),
    DurationMinutes INT           NOT NULL DEFAULT 0 CHECK (DurationMinutes >= 0),
    -- CONSTRAINT FK_Theory_Chapter FOREIGN KEY (ChapterID) REFERENCES CHAPTER(ChapterID)
);

-- DROP TABLE THEORY_LESSON;
CREATE TABLE USERTABLE (
    UserID              CHAR(10)        PRIMARY KEY,
    AccountName         VARCHAR(30)     NOT NULL,
    AccountPassword     VARCHAR(128)    NOT NULL,          -- Đã thay đổi để lưu bản băm (hash))
    FullName            NVARCHAR(100)   NOT NULL,         
    Email               VARCHAR(255)    NOT NULL,     
    PhoneNumber         VARCHAR(15),                        
    Nation              NVARCHAR(50),                   
    Province            NVARCHAR(50),                      
    Ward                NVARCHAR(50),                   
    EnrollmentDate      DATE,
    AccountState        BIT             NOT NULL    DEFAULT 1  -- Dùng BIT (1 = Active, 0 = Inactive)

    -- Đặt tên rõ ràng cho các ràng buộc Unique
    CONSTRAINT UQ_AccountName UNIQUE(AccountName),
    CONSTRAINT UQ_Email UNIQUE(Email)
);

-- DROP TABLE UserTable;





CREATE TABLE VIDEO_LESSON (
    VideoID         CHAR(10)        PRIMARY KEY,       
    ChapterID       CHAR(10)        NOT NULL,                   -- FOREIGN KEY
    Title           NVARCHAR(200)   NOT NULL,
    VideoURL        NVARCHAR(1000)  NOT NULL,
    DurationMinutes INT             NOT NULL    DEFAULT 0    CHECK (DurationMinutes > 0)
    -- CONSTRAINT FK_Video_Chapter FOREIGN KEY (ChapterID) REFERENCES CHAPTER(ChapterID)   
);

GO
ALTER TABLE ANSWER
ADD CONSTRAINT FK_ANSWER_QUESTION 
FOREIGN KEY (TestID, QuestionNo) REFERENCES QUESTION (TestID, QuestionNo)
ON DELETE CASCADE; -- Tùy chọn: Xóa câu hỏi thì xóa luôn các câu trả lời
-- Liên kết bảng CHAPTER với bảng COURSE
ALTER TABLE CHAPTER
ADD CONSTRAINT FK_CHAPTER_COURSE
FOREIGN KEY (CourseID) REFERENCES COURSE(CourseID);
-- 1. Người viết bình luận
ALTER TABLE COMMENTS
ADD CONSTRAINT FK_COMMENTS_USERTABLE
FOREIGN KEY (UserID) REFERENCES USERTABLE(UserID);

-- 2. Bình luận thuộc về Bài viết (Post)
ALTER TABLE COMMENTS
ADD CONSTRAINT FK_Comments_Post FOREIGN KEY (PostID)
REFERENCES POSTS(PostID);

-- 3. Bình luận thuộc về Khóa học (Course)
ALTER TABLE COMMENTS
ADD CONSTRAINT FK_COMMENTS_COURSE 
FOREIGN KEY (CourseID) REFERENCES COURSE(CourseID);

-- 4. Bình luận trả lời (Reply) - Tham chiếu về chính bảng COMMENTS
-- Vì khóa chính của COMMENTS là cặp (UserID, CreatedAt)
-- Nên khóa ngoại cũng phải tham chiếu đủ cả cặp này
ALTER TABLE COMMENTS
ADD CONSTRAINT FK_COMMENTS_REPLYTOCOMMENTS 
FOREIGN KEY (ReplyUserID, ReplyCreatedAt) REFERENCES COMMENTS(UserID, CreatedAt);





-- 1. Liên kết với bảng USERTABLE (Học viên đăng ký)
ALTER TABLE COURSE_ENROLLMENT
ADD CONSTRAINT FK_COURSE_ENROLLMENT_USERTABLE
FOREIGN KEY (UserID) REFERENCES USERTABLE(UserID);

-- 2. Liên kết với bảng COURSE (Khóa học được đăng ký)
ALTER TABLE COURSE_ENROLLMENT
ADD CONSTRAINT FK_COURSE_ENROLLMENT_COURSE
FOREIGN KEY (CourseID) REFERENCES COURSE(CourseID);
-- Liên kết bảng COURSE với bảng TEACHER (Giáo viên phụ trách)
ALTER TABLE COURSE
ADD CONSTRAINT FK_COURSE_TEACHER
FOREIGN KEY (TeacherID) REFERENCES TEACHER(TeacherID);
-- 1. Liên kết với bảng USERTABLE (Người đánh giá)
ALTER TABLE COURSE_RATING
ADD CONSTRAINT FK_COURSE_RATING_USERTABLE
FOREIGN KEY (UserID) REFERENCES USERTABLE(UserID);

-- 2. Liên kết với bảng COURSE (Khóa học được đánh giá)
ALTER TABLE COURSE_RATING
ADD CONSTRAINT FK_COURSE_RATING_COURSE
FOREIGN KEY (CourseID) REFERENCES COURSE(CourseID);
-- 1. Liên kết với bảng USERTABLE (Người làm bài)
ALTER TABLE EXERCISE_ATTEMPT
ADD CONSTRAINT FK_EXERCISE_ATTEMPT_USERTABLE
FOREIGN KEY (UserID) REFERENCES USERTABLE(UserID);

-- 2. Liên kết với bảng EXERCISE (Bài tập nào)
ALTER TABLE EXERCISE_ATTEMPT
ADD CONSTRAINT FK_EXERCISE_ATTEMPT_EXERCISE
FOREIGN KEY (ExerciseID) REFERENCES EXERCISE(ExerciseID);
-- 1. Liên kết bảng THEORY_LESSON với bảng CHAPTER
ALTER TABLE THEORY_LESSON
ADD CONSTRAINT FK_THEORY_LESSON_CHAPTER
FOREIGN KEY (ChapterID) REFERENCES CHAPTER(ChapterID);

-- 2. Liên kết bảng VIDEO_LESSON với bảng CHAPTER
ALTER TABLE VIDEO_LESSON
ADD CONSTRAINT FK_VIDEO_LESSON_CHAPTER
FOREIGN KEY (ChapterID) REFERENCES CHAPTER(ChapterID);

-- 3. Liên kết bảng EXERCISE với bảng CHAPTER
ALTER TABLE EXERCISE
ADD CONSTRAINT FK_EXERCISE_CHAPTER
FOREIGN KEY (ChapterID) REFERENCES CHAPTER(ChapterID);
-- Liên kết bảng POST với bảng USERTABLE
ALTER TABLE POSTS
ADD CONSTRAINT FK_POSTS_USERTABLE
FOREIGN KEY (UserID) REFERENCES USERTABLE(UserID);

-- Liên kết bảng PRACTICE với bảng TEACHER
ALTER TABLE PRACTICES
ADD CONSTRAINT FK_PRACTICES_TEACHER
FOREIGN KEY (TeacherID) REFERENCES TEACHER(TeacherID);
-- Liên kết bảng PRACTICE_ATTEMPT_INFO với bảng USERTABLE
ALTER TABLE PRACTICE_ATTEMPT_INFO
ADD CONSTRAINT FK_PRACTICE_ATTEMPT_INFO_USERTABLE
FOREIGN KEY (UserID) REFERENCES USERTABLE(UserID);

-- Liên kết bảng PRACTICE_ATTEMPT_INFO với bảng PRACTICES
ALTER TABLE PRACTICE_ATTEMPT_INFO
ADD CONSTRAINT FK_PRACTICE_ATTEMPT_INFO_PRACTICE
FOREIGN KEY (PracticeID) REFERENCES PRACTICES(PracticeID);
ALTER TABLE QUESTION
ADD CONSTRAINT FK_QUESTION_TEST 
FOREIGN KEY (TestID) REFERENCES TEST (TestID)
ON DELETE CASCADE; -- Tùy chọn: Xóa bài kiểm tra thì xóa luôn các câu hỏi bên trong
-- Liên kết bảng TEACHER_EDUCATION với bảng TEACHER
ALTER TABLE TEACHER_EDUCATION
ADD CONSTRAINT FK_TEACHER_EDUCATION_TEACHER
FOREIGN KEY (TeacherID) REFERENCES TEACHER(TeacherID)
ON DELETE CASCADE; -- Tùy chọn: Nếu xóa Giáo viên thì xóa luôn hồ sơ học vấn của họ
-- Liên kết bảng TEACHER với bảng USERTABLE
-- Ý nghĩa: TeacherID chính là UserID. Một người phải là User trước khi được làm Teacher.
ALTER TABLE TEACHER
ADD CONSTRAINT FK_TEACHER_USERTABLE
FOREIGN KEY (TeacherID) REFERENCES USERTABLE(UserID)
ON DELETE CASCADE; -- Tùy chọn: Nếu xóa User thì xóa luôn tư cách Teacher của họ
-- Liên kết bảng TEST_ATTEMPT_RECORDS với bảng USERTABLE (Người làm bài)
ALTER TABLE TEST_ATTEMPT_RECORDS
ADD CONSTRAINT FK_TEST_ATTEMPT_RECORDS_USERTABLE
FOREIGN KEY (UserID) REFERENCES USERTABLE(UserID);

-- Liên kết bảng TEST_ATTEMPT_RECORDS với bảng TEST (Bài kiểm tra nào)
ALTER TABLE TEST_ATTEMPT_RECORDS
ADD CONSTRAINT FK_TEST_ATTEMPT_RECORDS_TEST
FOREIGN KEY (TestID) REFERENCES TEST(TestID);
ALTER TABLE TEST
ADD CONSTRAINT FK_TEST_CHAPTER 
FOREIGN KEY (ChapterID) REFERENCES CHAPTER (ChapterID);

GO
-- 1. Chèn dữ liệu bảng USERTABLE (10 dòng - Teachers và Students)
INSERT INTO USERTABLE (UserID, AccountName, AccountPassword, FullName, Email, PhoneNumber, Nation, Province, Ward, EnrollmentDate, AccountState) VALUES 
('US001', 'teacher_minh', 'hash123', N'Nguyễn Nhật Minh', 'minh.nguyen@edu.vn', '0909111222', N'Việt Nam', N'TP.HCM', N'Quận 1', '2023-01-01', 1),
('US002', 'teacher_hang', 'hash123', N'Phạm Thu Hằng', 'hang.pham@edu.vn', '0909333444', N'Việt Nam', N'Hà Nội', N'Đống Đa', '2023-02-15', 1),
('US003', 'teacher_long', 'hash123', N'Trần Đức Long', 'long.tran@edu.vn', '0909555666', N'Việt Nam', N'Đà Nẵng', N'Hải Châu', '2023-03-10', 1),
('US004', 'student_nam', 'hash456', N'Trần Văn Nam', 'nam.tran@gmail.com', '0912000001', N'Việt Nam', N'Đà Nẵng', N'Thanh Khê', '2023-06-01', 1),
('US005', 'student_lan', 'hash456', N'Lê Thị Lan', 'lan.le@gmail.com', '0912000002', N'Việt Nam', N'Cần Thơ', N'Ninh Kiều', '2023-06-05', 1),
('US006', 'student_hung', 'hash456', N'Võ Quốc Hưng', 'hung.vo@gmail.com', '0912000003', N'Việt Nam', N'Bình Dương', N'Dĩ An', '2023-07-10', 1),
('US007', 'student_mai', 'hash456', N'Hoàng Ngọc Mai', 'mai.hoang@gmail.com', '0912000004', N'Việt Nam', N'TP.HCM', N'Thủ Đức', '2023-08-20', 1),
('US008', 'student_tuan', 'hash456', N'Nguyễn Anh Tuấn', 'tuan.nguyen@gmail.com', '0912000005', N'Việt Nam', N'Hà Nội', N'Cầu Giấy', '2023-09-01', 1),
('US009', 'student_linh', 'hash456', N'Phạm Thùy Linh', 'linh.pham@gmail.com', '0912000006', N'Việt Nam', N'TP.HCM', N'Quận 3', '2023-09-15', 1),
('US010', 'student_khoa', 'hash456', N'Lê Minh Khoa', 'khoa.le@gmail.com', '0912000007', N'Việt Nam', N'Hải Phòng', N'Lê Chân', '2023-10-01', 1);

-- 2. Chèn dữ liệu bảng TEACHER (3 giảng viên)
INSERT INTO TEACHER (TeacherID) VALUES 
('US001'),
('US002'),
('US003');

-- 3. Chèn dữ liệu bảng TEACHER_EDUCATION (6 dòng)
INSERT INTO TEACHER_EDUCATION (TeacherID, Degree, Major, School, StartTime, EndTime) VALUES 
('US001', N'Cử nhân', N'Khoa học Máy tính', N'Đại học Bách Khoa TP.HCM', '2010-09-01', '2014-06-30'),
('US001', N'Thạc sĩ', N'Trí tuệ Nhân tạo', N'Đại học Quốc gia Singapore', '2015-09-01', '2017-05-30'),
('US002', N'Cử nhân', N'Sư phạm Anh', N'Đại học Sư phạm Hà Nội', '2012-09-01', '2016-06-30'),
('US002', N'Thạc sĩ', N'Ngôn ngữ học', N'Đại học Hà Nội', '2017-09-01', '2019-12-30'),
('US003', N'Cử nhân', N'Công nghệ Thông tin', N'Đại học Đà Nẵng', '2011-09-01', '2015-06-30'),
('US003', N'Thạc sĩ', N'An toàn Thông tin', N'Đại học Bách Khoa Hà Nội', '2016-09-01', '2018-12-30');

-- SELECT * FROM USERTABLE; 
-- SELECT * FROM TEACHER;
-- SELECT * FROM TEACHER_EDUCATION;
-- 1. Chèn dữ liệu bảng COURSE (8 khóa học)
-- NumStudents khớp với số lượng trong COURSE_ENROLLMENT bên dưới
-- TotalDuration tính bằng GIỜ
INSERT INTO COURSE (CourseID, CourseName, CourseState, TeacherID, TotalDuration, AverageRating, NumStudents) VALUES 
('COU001', N'Lập trình SQL từ cơ bản đến nâng cao', N'Đang mở', 'US001', 25, 4.8, 5),
('COU002', N'Cấu trúc dữ liệu và giải thuật', N'Đang mở', 'US001', 35, 4.5, 3),
('COU003', N'Lập trình Web với ReactJS', N'Đang mở', 'US001', 28, 4.6, 4),
('COU004', N'Tiếng Anh giao tiếp công sở', N'Đang mở', 'US002', 30, 4.9, 4),
('COU005', N'Luyện thi TOEIC 650+', N'Đang mở', 'US002', 40, 4.7, 3),
('COU006', N'Python cho khoa học dữ liệu', N'Đang mở', 'US003', 32, 4.8, 2),
('COU007', N'An toàn và bảo mật thông tin', N'Đang mở', 'US003', 24, 4.5, 2),
('COU008', N'Machine Learning cơ bản', N'Sắp ra mắt', 'US001', 0, 0, 0);

-- 2. Chèn dữ liệu bảng CHAPTER (12 chương)
INSERT INTO CHAPTER (ChapterID, CourseID, ChapterTitle, ChapterOrder, ChapterDescription) VALUES 
-- COU001 - SQL
('CHAP01', 'COU001', N'Chương 1: Tổng quan về CSDL', 1, N'Giới thiệu khái niệm Database'),
('CHAP02', 'COU001', N'Chương 2: Truy vấn cơ bản SELECT', 2, N'Học cách lấy dữ liệu'),
('CHAP03', 'COU001', N'Chương 3: JOIN và Subquery', 3, N'Kết hợp nhiều bảng'),
-- COU002 - CTDL
('CHAP04', 'COU002', N'Chương 1: Độ phức tạp thuật toán', 1, N'Big O Notation'),
('CHAP05', 'COU002', N'Chương 2: Cấu trúc dữ liệu cơ bản', 2, N'Stack, Queue, Linked List'),
-- COU003 - ReactJS
('CHAP06', 'COU003', N'Chương 1: React Fundamentals', 1, N'Components, Props, State'),
('CHAP07', 'COU003', N'Chương 2: Hooks và State Management', 2, N'useState, useEffect, Context'),
-- COU004 - Tiếng Anh
('CHAP08', 'COU004', N'Unit 1: Greeting & Introduction', 1, N'Cách chào hỏi chuyên nghiệp'),
('CHAP09', 'COU004', N'Unit 2: Writing Emails', 2, N'Kỹ năng viết email'),
-- COU005 - TOEIC
('CHAP10', 'COU005', N'Part 1-2: Listening Comprehension', 1, N'Nghe hiểu hình ảnh và hỏi đáp'),
-- COU006 - Python
('CHAP11', 'COU006', N'Chương 1: Python Basics', 1, N'Cú pháp cơ bản, biến, vòng lặp'),
-- COU007 - An toàn TT
('CHAP12', 'COU007', N'Chương 1: Mã hóa và Cryptography', 1, N'Các thuật toán mã hóa');

-- SELECT * FROM COURSE;
-- SELECT * FROM CHAPTER;
-- 1. THEORY_LESSON (4 dòng)
INSERT INTO THEORY_LESSON (TheoryLessonID, ChapterID, Title, Content, DurationMinutes) VALUES 
('TL001', 'CHAP01', N'Dữ liệu và Thông tin', N'Khái niệm cơ bản...', 10),
('TL002', 'CHAP01', N'Các loại CSDL phổ biến', N'SQL vs NoSQL...', 15),
('TL003', 'CHAP04', N'Formal vs Informal Greetings', N'When to use Hello vs Hi...', 10),
('TL004', 'CHAP05', N'Email Structure', N'Subject, Body, Signature...', 20);

-- 2. VIDEO_LESSON (4 dòng)
INSERT INTO VIDEO_LESSON (VideoID, ChapterID, Title, VideoURL, DurationMinutes) VALUES 
('VL001', 'CHAP01', N'Cài đặt SQL Server Management Studio', N'https://youtu.be/demo1', 25),
('VL002', 'CHAP02', N'Thực hành lệnh SELECT', N'https://youtu.be/demo2', 30),
('VL003', 'CHAP03', N'Phân tích thuật toán sắp xếp', N'https://youtu.be/demo3', 40),
('VL004', 'CHAP04', N'Mẫu câu giao tiếp thông dụng', N'https://youtu.be/demo4', 15);

-- 3. EXERCISE (4 dòng)
INSERT INTO EXERCISE (ExerciseID, ChapterID, Title, ExDescription, SampleAnswer, MinPassingScore) VALUES 
('EX001', 'CHAP01', N'Phân biệt Database', N'Hãy so sánh SQL và Excel...', N'SQL quản lý dữ liệu lớn tốt hơn...', 50),
('EX002', 'CHAP02', N'Viết câu lệnh SELECT', N'Lấy tên và email user...', N'SELECT FullName, Email FROM USERTABLE', 60),
('EX003', 'CHAP04', N'Roleplay Greeting', N'Ghi âm đoạn hội thoại...', N'File Audio', 50),
('EX004', 'CHAP05', N'Viết Email xin nghỉ phép', N'Viết email gửi sếp...', N'Dear Mr.A...', 70);

-- SELECT * FROM THEORY_LESSON;
-- SELECT * FROM VIDEO_LESSON;
-- SELECT * FROM EXERCISE;
-- 1. TEST (2 bài kiểm tra)
INSERT INTO TEST (TestID, TestName, TestDuration, ScoreToPass, TotalScore, ChapterID) VALUES 
('TST01', N'Kiểm tra Trắc nghiệm SQL', 30, 50, 100, 'CHAP01'),
('TST02', N'Kiểm tra Từ vựng Tiếng Anh', 15, 60, 100, 'CHAP04');

-- 2. QUESTION (4 dòng)
-- 2 câu cho bài SQL
INSERT INTO QUESTION (TestID, QuestionNo, QuestionContent, Score) VALUES 
('TST01', 1, N'SQL là viết tắt của từ gì?', 50),
('TST01', 2, N'Lệnh nào dùng để xóa bảng?', 50);

-- 2 câu cho bài Tiếng Anh
INSERT INTO QUESTION (TestID, QuestionNo, QuestionContent, Score) VALUES 
('TST02', 1, N'Từ nào có nghĩa là "Đồng nghiệp"?', 50),
('TST02', 2, N'Quá khứ của "Go" là gì?', 50);

-- 3. ANSWER (8 dòng - Mỗi câu 2 đáp án)
INSERT INTO ANSWER (TestID, QuestionNo, AnswerNo, AnswerContent, IsCorrect) VALUES 
('TST01', 1, 1, N'Structured Query Language', 1), -- Đúng
('TST01', 1, 2, N'Strong Question List', 0),
('TST01', 2, 1, N'DELETE', 0),
('TST01', 2, 2, N'DROP', 1), -- Đúng
('TST02', 1, 1, N'Colleague', 1), -- Đúng
('TST02', 1, 2, N'College', 0),
('TST02', 2, 1, N'Gone', 0),
('TST02', 2, 2, N'Went', 1); -- Đúng

-- SELECT * FROM TEST;
-- SELECT * FROM QUESTION;
-- SELECT * FROM ANSWER;
-- 1. POST (8 bài viết)
INSERT INTO POSTS (PostID, Title, Content, UserID) VALUES 
('POS01', N'Lộ trình học SQL cho người mới', N'Chia sẻ kinh nghiệm từ cơ bản đến nâng cao...', 'US004'),
('POS02', N'Làm sao để học từ vựng nhanh?', N'Mẹo học Flashcard và Spaced Repetition...', 'US005'),
('POS03', N'Review khóa học ReactJS', N'Khóa học rất hay, giảng viên nhiệt tình...', 'US007'),
('POS04', N'Tìm bạn học nhóm TOEIC', N'Mình đang học TOEIC, cần tìm bạn cùng luyện...', 'US006'),
('POS05', N'Cấu trúc dữ liệu quan trọng như thế nào?', N'Chia sẻ về tầm quan trọng của CTDL trong lập trình...', 'US004'),
('POS06', N'Tips học Python hiệu quả', N'Những mẹo học Python cho người mới bắt đầu...', 'US008'),
('POS07', N'An toàn thông tin trong thời đại 4.0', N'Tầm quan trọng của bảo mật dữ liệu...', 'US009'),
('POS08', N'So sánh SQL vs NoSQL', N'Phân tích ưu nhược điểm của 2 loại database...', 'US010');

-- 2. COMMENT (12 bình luận)
INSERT INTO COMMENTS (UserID, CreatedAt, Content, ReplyCount, PostID) VALUES 
('US005', '2023-11-20 08:00:00', N'Cảm ơn bài chia sẻ hữu ích!', 0, 'POS01'),
('US006', '2023-11-20 09:00:00', N'Mình cũng đang học theo lộ trình này.', 0, 'POS01'),
('US004', '2023-11-21 10:00:00', N'Inbox mình nhé!', 0, 'POS04'),
('US007', '2023-11-21 11:00:00', N'Bài viết rất chi tiết.', 0, 'POS02'),
('US008', '2023-11-22 14:00:00', N'Khóa học ReactJS thực sự tuyệt vời!', 0, 'POS03'),
('US009', '2023-11-22 15:30:00', N'Mình cũng muốn tham gia nhóm học TOEIC', 0, 'POS04'),
('US005', '2023-11-23 09:00:00', N'CTDL rất quan trọng cho phỏng vấn!', 0, 'POS05'),
('US010', '2023-11-23 10:00:00', N'Python dễ học hơn mình nghĩ', 0, 'POS06'),
('US006', '2023-11-24 08:00:00', N'Bảo mật thông tin ngày càng quan trọng', 0, 'POS07'),
('US007', '2023-11-24 16:00:00', N'Bài so sánh rất khách quan', 0, 'POS08'),
('US004', '2023-11-25 11:00:00', N'Có ai học SQL cùng mình không?', 0, 'POS01'),
('US008', '2023-11-25 14:00:00', N'NoSQL phù hợp cho big data hơn', 0, 'POS08');

-- SELECT * FROM POSTS;
-- SELECT * FROM COMMENTS;
-- 1. COURSE_ENROLLMENT (23 enrollments)
INSERT INTO COURSE_ENROLLMENT (UserID, CourseID, EnrollmentDate) VALUES 
-- COU001 - 5 students
('US004', 'COU001', '2023-06-02'),
('US005', 'COU001', '2023-06-06'),
('US006', 'COU001', '2023-07-11'),
('US007', 'COU001', '2023-08-15'),
('US008', 'COU001', '2023-09-01'),
-- COU002 - 3 students
('US004', 'COU002', '2023-07-01'),
('US006', 'COU002', '2023-08-01'),
('US009', 'COU002', '2023-09-10'),
-- COU003 - 4 students
('US005', 'COU003', '2023-09-05'),
('US007', 'COU003', '2023-09-20'),
('US009', 'COU003', '2023-10-01'),
('US010', 'COU003', '2023-10-15'),
-- COU004 - 4 students
('US004', 'COU004', '2023-06-10'),
('US005', 'COU004', '2023-07-05'),
('US008', 'COU004', '2023-09-01'),
('US010', 'COU004', '2023-10-01'),
-- COU005 - 3 students
('US006', 'COU005', '2023-08-21'),
('US007', 'COU005', '2023-09-10'),
('US009', 'COU005', '2023-10-05'),
-- COU006 - 2 students
('US008', 'COU006', '2023-09-15'),
('US010', 'COU006', '2023-10-20'),
-- COU007 - 2 students
('US005', 'COU007', '2023-09-25'),
('US009', 'COU007', '2023-10-10');

-- 2. COURSE_RATING (15 ratings)
INSERT INTO COURSE_RATING (UserID, CourseID, RatingValue) VALUES 
('US004', 'COU001', 5),
('US005', 'COU001', 4),
('US006', 'COU001', 5),
('US007', 'COU001', 5),
('US008', 'COU001', 5),
('US004', 'COU002', 4),
('US006', 'COU002', 5),
('US005', 'COU003', 5),
('US007', 'COU003', 4),
('US004', 'COU004', 5),
('US005', 'COU004', 5),
('US006', 'COU005', 5),
('US007', 'COU005', 4),
('US008', 'COU006', 5),
('US005', 'COU007', 4);

-- 3. TEST_ATTEMPT (8 lần thi)
INSERT INTO TEST_ATTEMPT_RECORDS (UserID, TestID, StartTime, SubmitTime, Score) VALUES 
('US004', 'TST01', '2023-07-02 08:00:00', '2023-07-02 08:30:00', 100),
('US005', 'TST01', '2023-07-06 09:00:00', '2023-07-06 09:30:00', 50),
('US006', 'TST01', '2023-07-15 10:00:00', '2023-07-15 10:30:00', 75),
('US007', 'TST01', '2023-08-20 14:00:00', '2023-08-20 14:30:00', 85),
('US004', 'TST02', '2023-07-10 08:00:00', '2023-07-10 08:15:00', 90),
('US005', 'TST02', '2023-07-12 09:00:00', '2023-07-12 09:15:00', 80),
('US008', 'TST02', '2023-09-05 10:00:00', '2023-09-05 10:15:00', 70),
('US010', 'TST02', '2023-10-15 11:00:00', '2023-10-15 11:15:00', 95);

-- 4. PRACTICE (3 bài thực hành)
INSERT INTO PRACTICES (PracticeID, Title, Difficulty, Content, TeacherID) VALUES 
('PRA01', N'Viết Query Join', N'Trung bình', N'Kết hợp bảng User và Course để lấy danh sách enrollment', 'US001'),
('PRA02', N'Implement Stack', N'Khó', N'Cài đặt Stack bằng Array hoặc Linked List', 'US001'),
('PRA03', N'Build Todo App', N'Trung bình', N'Xây dựng ứng dụng quản lý công việc với React', 'US001');

-- PRACTICE_ATTEMPT (6 lần làm)
INSERT INTO PRACTICE_ATTEMPT_INFO (UserID, PracticeID, StartTime, SubmitTime, Score) VALUES 
('US004', 'PRA01', '2023-07-03 14:00:00', '2023-07-03 15:00:00', 90),
('US005', 'PRA01', '2023-07-08 10:00:00', '2023-07-08 11:30:00', 75),
('US006', 'PRA01', '2023-07-20 15:00:00', '2023-07-20 16:00:00', 85),
('US004', 'PRA02', '2023-08-05 09:00:00', '2023-08-05 11:00:00', 80),
('US006', 'PRA02', '2023-08-15 14:00:00', '2023-08-15 16:30:00', 70),
('US005', 'PRA03', '2023-09-10 10:00:00', '2023-09-10 13:00:00', 88);

-- 5. EXERCISE_ATTEMPT (10 lần làm bài tập)
INSERT INTO EXERCISE_ATTEMPT (UserID, ExerciseID, StartTime, SubmitTime, Score) VALUES 
('US004', 'EX001', '2023-07-15 14:00:00', '2023-07-15 14:45:00', 85.5),
('US005', 'EX001', '2023-07-16 09:00:00', '2023-07-16 10:00:00', 90.0),
('US006', 'EX001', '2023-07-18 15:00:00', '2023-07-18 15:30:00', 75.0),
('US004', 'EX002', '2023-07-20 20:00:00', '2023-07-20 20:30:00', 60.0),
('US005', 'EX002', '2023-07-21 08:00:00', '2023-07-21 08:15:00', 95.0),
('US007', 'EX002', '2023-08-22 10:00:00', '2023-08-22 10:20:00', 85.0),
('US004', 'EX003', '2023-07-12 14:00:00', '2023-07-12 14:30:00', 70.0),
('US005', 'EX003', '2023-07-18 16:00:00', '2023-07-18 16:25:00', 80.0),
('US004', 'EX004', '2023-07-25 09:00:00', '2023-07-25 09:40:00', 88.0),
('US010', 'EX004', '2023-10-20 11:00:00', '2023-10-20 11:35:00', 92.0);

-- SELECT * FROM COURSE_ENROLLMENT;
-- SELECT * FROM COURSE_RATING;
-- SELECT * FROM TEST_ATTEMPT_RECORDS;
-- SELECT * FROM PRACTICES;
-- SELECT * FROM PRACTICE_ATTEMPT_INFO;
-- SELECT * FROM EXERCISE_ATTEMPT;

GO

-- FUNCTIONS

-- Function 1: Tính điểm trung bình của học viên
CREATE FUNCTION fn_CalculateStudentAvgScore (@UserID CHAR(10))
RETURNS DECIMAL(5, 2)
AS
BEGIN
    DECLARE @AvgScore DECIMAL(5, 2);

    -- Tính trung bình cộng cột Score từ bảng TEST_ATTEMPT
    SELECT @AvgScore = AVG(Score)
    FROM TEST_ATTEMPT_RECORDS
    WHERE UserID = @UserID;

    -- Nếu chưa làm bài nào thì trả về 0
    RETURN ISNULL(@AvgScore, 0);
END;
GO

-- Function 2: Lấy danh sách khóa học của giảng viên
CREATE FUNCTION fn_GetCoursesByTeacher (@TeacherID CHAR(10))
RETURNS TABLE
AS
RETURN
(
    SELECT 
        C.CourseID, 
        C.CourseName, 
        C.AverageRating, 
        C.NumStudents
    FROM COURSE C
    WHERE C.TeacherID = @TeacherID
);
GO

PRINT N'Da tao 2 Functions';
GO

-- STORED PROCEDURES

-- Procedure 1: Lấy danh sách top học viên
CREATE PROCEDURE sp_GetTopStudents
    @MinScore DECIMAL(5, 2) -- Tham số đầu vào (Input parameter)
AS
BEGIN
    -- Query kết hợp bảng USERTABLE và TEST_ATTEMPT
    SELECT 
        U.UserID,
        U.FullName,
        U.Email,
        COUNT(TA.TestID) AS TotalTestsTaken, -- Aggregate Function
        AVG(TA.Score) AS AverageScore        -- Aggregate Function
    FROM USERTABLE U
    JOIN TEST_ATTEMPT_RECORDS TA ON U.UserID = TA.UserID
    GROUP BY U.UserID, U.FullName, U.Email -- GROUP BY
    HAVING AVG(TA.Score) >= @MinScore      -- HAVING với Input parameter
    ORDER BY AverageScore DESC;            -- ORDER BY
END;
GO

-- Procedure 2: Đăng ký khóa học
CREATE PROCEDURE sp_EnrollCourse
    @UserID CHAR(10),
    @CourseID CHAR(10)
AS
BEGIN
    -- 1. Validation: Kiểm tra User có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM USERTABLE WHERE UserID = @UserID)
    BEGIN
        PRINT N'Lỗi: Người dùng không tồn tại.';
        RETURN;
    END

    -- 2. Validation: Kiểm tra Khóa học có tồn tại và ĐANG MỞ không
    IF NOT EXISTS (SELECT 1 FROM COURSE WHERE CourseID = @CourseID AND CourseState = N'Đang mở')
    BEGIN
        PRINT N'Lỗi: Khóa học không tồn tại hoặc chưa mở đăng ký.';
        RETURN;
    END

    -- 3. Validation: Kiểm tra đã đăng ký chưa
    IF EXISTS (SELECT 1 FROM COURSE_ENROLLMENT WHERE UserID = @UserID AND CourseID = @CourseID)
    BEGIN
        PRINT N'Lỗi: Học viên đã đăng ký khóa học này rồi.';
        RETURN;
    END

    -- 4. Thực hiện Insert (Nếu vượt qua mọi kiểm tra)
    INSERT INTO COURSE_ENROLLMENT (UserID, CourseID, EnrollmentDate)
    VALUES (@UserID, @CourseID, GETDATE());

    PRINT N'Đăng ký thành công!';
END;
GO

PRINT N'Da tao 2 Stored Procedures';
GO

-- TRIGGERS

-- Trigger 1: Tự động cập nhật NumStudents khi có enrollment
CREATE TRIGGER trg_UpdateNumStudents
ON COURSE_ENROLLMENT
AFTER INSERT, DELETE
AS
BEGIN
    -- Trường hợp 1: Có người mới đăng ký (INSERT)
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        UPDATE COURSE
        SET NumStudents = NumStudents + 1
        FROM COURSE C
        JOIN inserted I ON C.CourseID = I.CourseID;
    END

    -- Trường hợp 2: Có người hủy đăng ký (DELETE)
    IF EXISTS (SELECT * FROM deleted)
    BEGIN
        UPDATE COURSE
        SET NumStudents = NumStudents - 1
        FROM COURSE C
        JOIN deleted D ON C.CourseID = D.CourseID;
    END
END;
GO

-- Trigger 2: Kiểm tra điều kiện đánh giá (phải enroll trước)
CREATE TRIGGER trg_CheckRatingCondition
ON COURSE_RATING
FOR INSERT
AS
BEGIN
    DECLARE @UserID CHAR(10);
    DECLARE @CourseID CHAR(10);

    -- Lấy thông tin từ dòng dữ liệu đang định chèn vào
    SELECT @UserID = UserID, @CourseID = CourseID FROM inserted;

    -- Kiểm tra xem User này có trong bảng Enrollment chưa
    IF NOT EXISTS (SELECT 1 FROM COURSE_ENROLLMENT WHERE UserID = @UserID AND CourseID = @CourseID)
    BEGIN
        RAISERROR (N'Lỗi: Bạn phải đăng ký khóa học trước khi đánh giá.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

PRINT N'Da tao 2 Triggers';
GO

-- Kiểm tra kết quả
SELECT 
    'Functions' AS ObjectType, 
    COUNT(*) AS Count 
FROM sys.objects 
WHERE type IN ('FN','IF')
UNION ALL
SELECT 'Procedures', COUNT(*) FROM sys.procedures
UNION ALL
SELECT 'Triggers', COUNT(*) FROM sys.triggers;

GO
-- Kiểm tra và xóa user nếu đã tồn tại
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'sManager')
BEGIN
    DROP USER sManager;
    PRINT N'Đã xóa user sManager cũ';
END
GO

-- Kiểm tra và xóa login nếu đã tồn tại
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'sManager')
BEGIN
    DROP LOGIN sManager;
    PRINT N'Đã xóa login sManager cũ';
END
GO

-- Tạo SQL Server Login
CREATE LOGIN sManager 
WITH PASSWORD = 'sManager',
     DEFAULT_DATABASE = ElearningDB,
     CHECK_POLICY = OFF;
GO

-- Tạo Database User
CREATE USER sManager FOR LOGIN sManager;
GO

-- Gán quyền db_owner (full access)
ALTER ROLE db_owner ADD MEMBER sManager;
GO

PRINT N'========================================';
PRINT N'Da tao user sManager thanh cong!';
PRINT N'Login: sManager';
PRINT N'Password: sManager';
PRINT N'Role: db_owner (Full access)';
PRINT N'========================================';
GO

-- Kiểm tra quyền
SELECT 
    dp.name AS UserName,
    dp.type_desc AS UserType,
    r.name AS RoleName
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
WHERE dp.name = 'sManager';
