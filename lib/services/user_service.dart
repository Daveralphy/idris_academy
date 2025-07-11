import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:idris_academy/models/comment_model.dart';
import 'package:idris_academy/models/course_model.dart';
import 'package:idris_academy/models/post_model.dart';
import 'package:idris_academy/models/user_model.dart';
import 'package:idris_academy/models/user_data_model.dart';
import 'package:idris_academy/models/notification_model.dart';
import 'package:idris_academy/models/chat_message_model.dart';
import 'package:idris_academy/models/module_model.dart';
import 'package:idris_academy/models/quiz_attempt_model.dart';
import 'package:idris_academy/models/submodule_model.dart';
import 'package:idris_academy/models/quiz_model.dart';
import 'package:idris_academy/models/announcement_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class UserService extends ChangeNotifier {
  // This is where you would place your secret key to connect to a real database.
  // final String _apiKey = 'YOUR_DATABASE_API_KEY_HERE';

  // Key for storing the logged-in user's ID in SharedPreferences.
  static const String _loggedInUserIdKey = 'loggedInUserId';

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  AnnouncementModel? _importantAnnouncement;
  AnnouncementModel? get importantAnnouncement => _importantAnnouncement;

  // Tracks if the important announcement has been shown in the current session.
  bool announcementShownThisSession = false;

  bool get isLoggedIn => _currentUser != null;

  // Getter to check if the current user has the 'teacher' role.
  // NOTE: This assumes your `UserModel` in `user_model.dart` has a `role` property.
  bool get isTeacher => _currentUser?.role == 'teacher';

  // Centralized mock user definitions.
  final Map<String, UserModel> _mockUsers = {
    'uid_12345': UserModel(
      id: 'uid_12345',
      name: 'Raphael (Student)',
      username: 'testuser',
      email: 'testuser@gmail.com',
      dob: DateTime(1995, 5, 23),
      phoneNumber: '+2348012345678',
      role: 'student',
    ),
    'uid_teacher': UserModel(
      id: 'uid_teacher',
      name: 'Dr. Idris',
      username: 'teacher',
      email: 'teacher@example.com',
      role: 'teacher',
    ),
    'uid_67890': UserModel(
      id: 'uid_67890',
      name: 'Aisha Bello',
      username: 'aisha',
      email: 'aisha@example.com',
      role: 'student',
      profilePicturePath: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=1961&auto=format&fit=crop',
    ),
  };

  // This map acts as a mock password storage.
  final Map<String, String> _mockUserPasswords = {
    'uid_12345': 'testpassword',
    'uid_teacher': 'teacherpass', // Teacher user for demonstration
    'uid_67890': 'aishapass',
  };

  // This map acts as our in-memory mock database.
  // The key is the user ID.
  final Map<String, UserData> _mockDatabase = {
    'uid_12345': UserData(
      inProgressCourses: [
        CourseModel(
            id: 'c1',
            title: 'Flutter UI Masterclass',
            description: 'Master the art of creating complex and beautiful UIs with Flutter.',
            thumbnailUrl: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?q=80&w=2070&auto=format&fit=crop',
            tags: ['Flutter', 'Advanced'],
            progress: 0.65,
            lastAccessedSubmoduleId:
                'sub1_1_2', // Example: User last viewed 'States of Matter'
            teacherName: 'Dr. Idris',
            hasGradedQuizzes: true,
            hasFinalExam: true,
            hasCertificate: true,
            certificatePassingGrade: 85),
        CourseModel(
            id: 'c2',
            title: 'State Management with Provider',
            description:
                'Learn the most popular state management solution for Flutter applications.',
            thumbnailUrl: 'https://images.unsplash.com/photo-1628258334105-2a0b3d6ef5f3?q=80&w=1974&auto=format&fit=crop',
            tags: ['Flutter', 'State Management'],
            progress: 0.30,
            lastAccessedSubmoduleId:
                'sub2_1_1', // Example: User last viewed 'The Cell'
            teacherName: 'Dr. Idris',
            hasGradedQuizzes: true,
            hasFinalExam: false,
            hasCertificate: false),
      ],
      recommendedCourses: [
        CourseModel(
            id: 'cat3',
            title: 'Mastering Newtonian Physics',
            description:
                'From kinematics to dynamics, understand the fundamentals of classical mechanics.',
            thumbnailUrl: 'https://www.shutterstock.com/image-vector/physics-chalkboard-background-hand-drawn-260nw-1988419205.jpg',
            tags: ['Physics', 'Advanced'],
            teacherName: 'Dr. Idris',
            hasGradedQuizzes: true,
            hasFinalExam: true,
            hasCertificate: true,
            certificatePassingGrade: 70),
        CourseModel(
            id: 'cat4',
            title: 'Calculus for Further Maths',
            description:
                'A deep dive into differentiation and integration for advanced problem-solving.',
            thumbnailUrl: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?q=80&w=2070&auto=format&fit=crop',
            tags: ['Further Maths', 'Mathematics', 'Calculus'],
            teacherName: 'Dr. Idris',
            hasGradedQuizzes: false,
            hasFinalExam: false,
            hasCertificate: false),
      ],
      achievements: {'Courses Done': '5', 'Badges Earned': '12', 'Time Spent': '72h'},
      notificationCount: 3,
      paymentPlan: 'Premium Annual',
      notifications: [
        NotificationModel(
          id: 'n1',
          title: 'New Lesson Available!',
          body: 'A new lesson "Advanced State Management" has been added to your Flutter course.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          type: NotificationType.courseUpdate,
          isRead: false,
        ),
        NotificationModel(
          id: 'n2',
          title: 'Message from Instructor',
          body: 'John Doe sent you a message regarding your last assignment.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          sender: 'John Doe',
          type: NotificationType.message,
          isRead: false,
        ),
        NotificationModel(
          id: 'n3',
          title: 'Platform Maintenance',
          body: 'Scheduled maintenance this Sunday at 2 AM.',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          type: NotificationType.announcement,
          isRead: true,
        ),
        NotificationModel(
            id: 'n4', title: 'Assignment Due Soon', body: 'Your "Slivers" assignment is due in 2 days.', timestamp: DateTime.now().subtract(const Duration(days: 5)), type: NotificationType.courseUpdate, isRead: false),
      ],
      supportChatHistory: [
        ChatMessageModel(
          id: 'msg1',
          text: 'Hello! I am the Idris Academy support bot. How can I help you today? You can ask me about navigating the app, finding courses, or checking your progress.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isSentByUser: false,
        ),
      ],
      quizAttempts: [],
    ),
    // The new user 'uid_67890' has no data yet.
  };

  // This list acts as our central feed for the Arena page.
  final List<PostModel> _arenaPosts = [
    PostModel(
      id: 'post1',
      authorId: 'uid_teacher',
      authorName: 'Dr. Idris',
      authorProfilePictureUrl: null, // Dr Idris doesn't have one, will show default icon
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      text: 'Welcome to the new Arena! This is a place for students to connect, share ideas, and help each other. Feel free to start a discussion.',
      likeCount: 15,
      comments: [
        CommentModel(
          id: 'c1_1',
          authorId: 'uid_12345',
          authorName: 'Raphael (Student)',
          authorProfilePictureUrl: null, // Raphael doesn't have one
          timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
          text: 'This is a great idea! Looking forward to it.',
        ),
      ],
    ),
    PostModel(
      id: 'post2',
      authorId: 'uid_67890', // New student Aisha
      authorName: 'Aisha Bello',
      authorProfilePictureUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=1961&auto=format&fit=crop',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      text: 'Has anyone started the "Mastering Newtonian Physics" course? I\'m finding the first module on Kinematics a bit challenging. Any tips?',
      likeCount: 5,
      isLikedByUser: true, // Let's say the current user (Raphael) liked this.
      comments: [],
    ),
    PostModel(
      id: 'post3',
      authorId: 'uid_12345',
      authorName: 'Raphael (Student)',
      authorProfilePictureUrl: null,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      text: 'Just finished the "Complete Secondary School Chemistry" course. The module on Chemical Reactions was fantastic. Highly recommend it!',
      imageUrl: 'https://media.istockphoto.com/id/469951129/photo/group-of-multi-ethnic-students-in-chemistry-lab.jpg?s=612x612&w=0&k=20&c=WbKS_5P0HrNGWXTmNifwjh6Dw0mzj_spghkbJYd9xnY=',
      likeCount: 22,
      comments: [],
    ),
  ];

  /// Loads the user session from local storage when the app starts.
  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_loggedInUserIdKey);

    if (userId != null && _mockUsers.containsKey(userId)) {
      _currentUser = _mockUsers[userId];
      _initializeUserDataForLogin(userId);
      _loadImportantAnnouncement();
      // No need to call notifyListeners() here, as this happens before the UI is built.
    }
  }

  Future<bool> login(String emailOrUsername, String password) async {
    // In a real app, you would make a network request to your backend here.
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    // Find the user by email or username, handling the case where no user is found.
    UserModel? user;
    try {
      user = _mockUsers.values.firstWhere(
        (u) => u.username.toLowerCase() == emailOrUsername.toLowerCase() || u.email.toLowerCase() == emailOrUsername.toLowerCase(),
      );
    } on StateError {
      // User not found, so 'user' remains null.
    }

    if (user != null) {
      // Check if the password is correct for the found user.
      if (_mockUserPasswords[user.id] == password) {
        _currentUser = user;
        _initializeUserDataForLogin(_currentUser!.id);
        announcementShownThisSession = false; // Reset on new login
        _loadImportantAnnouncement();
        // Save session to storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_loggedInUserIdKey, _currentUser!.id);
        notifyListeners(); // Notify widgets that the user has logged in.
        return true;
      }
    }
    return false;
  }

  Future<String?> signup(String name, String username, String email, DateTime? dob, String? phoneNumber, String token, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    // In a real app, you'd check if the email is already registered in the database.
    // Check if the email is already registered in our mock user data.
    if (_mockUsers.values.any((user) => user.email.toLowerCase() == email.toLowerCase())) {
      return 'This email is already registered.';
    }

    // Mock token validation
    if (token != 'IDRIS2024') {
      return 'Invalid token. Please check your email or get a new token.';
    }

    // Create a new user
    final newId = 'uid_${DateTime.now().millisecondsSinceEpoch}'; // Simple unique ID for mock purposes
    _currentUser = UserModel(
      id: newId,
      name: name,
      username: username,
      email: email,
      dob: dob,
      phoneNumber: phoneNumber,
      role: 'student', // New users default to 'student' role
    );
    // Add the new user to our mock collections
    _mockUsers[newId] = _currentUser!;
    _mockUserPasswords[newId] = password;

    _initializeUserDataForLogin(newId);
    _getCurrentUserData();
    announcementShownThisSession = false; // Reset on new login
    _loadImportantAnnouncement();

    // Save session to storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedInUserIdKey, _currentUser!.id);

    // Notify listeners that the user is now logged in.
    notifyListeners();

    return null; // Indicates success (no error message)
  }

  Future<void> logout() async {
    _currentUser = null;
    announcementShownThisSession = false; // Reset on logout

    // Clear session from storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInUserIdKey);

    notifyListeners(); // Notify widgets that the user has logged out.
  }

  // Helper to ensure user data is initialized with catalog courses on login/signup
  void _initializeUserDataForLogin(String userId) {
    // Ensure the user has a UserData entry with all catalog courses (not enrolled yet)
    _mockDatabase.putIfAbsent(userId, () => UserData(inProgressCourses: [], recommendedCourses: [], achievements: {}, notificationCount: 0, paymentPlan: 'Free Tier', notifications: [], supportChatHistory: [], quizAttempts: []));
  }

  void markAnnouncementAsShown() {
    announcementShownThisSession = true;
  }

  void _loadImportantAnnouncement() {
    // In a real app, this would be fetched from the backend.
    // You can toggle `isEnabled` to control the pop-up.
    _importantAnnouncement = AnnouncementModel(
      id: 'n3', // Corresponds to the platform maintenance notification
      title: 'Platform Maintenance',
      message: 'Scheduled maintenance this Sunday at 2 AM. The platform will be unavailable for 30 minutes.',
      isEnabled: true, // This is the on/off switch
    );
  }

  // --- Profile Update Methods ---

  /// Verifies the user's current password.
  Future<bool> verifyPassword(String password) async {
    if (!isLoggedIn) return false;
    // Simulate a network call to verify the password
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockUserPasswords[_currentUser!.id] == password;
  }

  /// Updates the user's name.
  Future<void> updateUserName(String newName) async {
    if (_currentUser != null) {
      _currentUser!.name = newName;
      // In a real app, you'd save this to the database.
      await Future.delayed(const Duration(milliseconds: 300));
      notifyListeners();
    }
  }

  /// Updates the user's phone number.
  Future<void> updatePhoneNumber(String newPhoneNumber) async {
    if (_currentUser != null) {
      _currentUser!.phoneNumber = newPhoneNumber;
      await Future.delayed(const Duration(milliseconds: 300));
      notifyListeners();
    }
  }

  /// Updates the user's password.
  Future<void> updatePassword(String newPassword) async {
    if (_currentUser != null) {
      // In a real app, this would be securely hashed and stored.
      _mockUserPasswords[_currentUser!.id] = newPassword;
      await Future.delayed(const Duration(milliseconds: 500));
      // No need to notifyListeners() as the password is not displayed.
    }
  }

  /// Updates the user's profile picture path.
  Future<void> updateProfilePicture(String path) async {
    if (_currentUser != null) {
      _currentUser!.profilePicturePath = path;
      notifyListeners();
    }
  }

  // --- Mock Data Methods ---
  // In a real app, these methods would fetch data from your database
  // for the _currentUser.

  UserData? _getCurrentUserData() {
    if (!isLoggedIn) return null;
    // Fetch data for the current user, or create empty data if they are new.
    return _mockDatabase.putIfAbsent(
        _currentUser!.id,
        () => UserData(
            inProgressCourses: [],
            recommendedCourses: [],
            achievements: {},
            notificationCount: 0,
            paymentPlan: 'Free Tier',
            notifications: [],
            supportChatHistory: [
              // Add the initial welcome message for new users as well.
              ChatMessageModel(
                  id: 'msg1', text: 'Hello! I am the Idris Academy support bot. How can I help you today? You can ask me about navigating the app, finding courses, or checking your progress.', timestamp: DateTime.now(), isSentByUser: false),
            ],
            quizAttempts: []
            )
        );
  }

  List<CourseModel> getInProgressCourses() => _getCurrentUserData()?.inProgressCourses ?? [];

  List<CourseModel> getRecommendedCourses() => _getCurrentUserData()?.recommendedCourses ?? [];

  Map<String, String> getAchievements() => _getCurrentUserData()?.achievements ?? {};

  int getNotificationCount() {
    final notifications = _getCurrentUserData()?.notifications ?? [];
    return notifications.where((n) => !n.isRead).length;
  }

  List<NotificationModel> getNotifications() {
    final notifications = _getCurrentUserData()?.notifications ?? [];
    // Sort by most recent first
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return notifications;
  }

  String getPaymentPlan() => _getCurrentUserData()?.paymentPlan ?? 'N/A';

  void markAllNotificationsAsRead() {
    final notifications = _getCurrentUserData()?.notifications;
    if (notifications != null) {
      for (var notification in notifications) {
        notification.isRead = true;
      }
      notifyListeners();
    }
  }

  void markNotificationAsRead(String id) {
    final notifications = _getCurrentUserData()?.notifications;
    if (notifications != null) {
      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        notifications[index].isRead = true;
        notifyListeners();
      }
    }
  }

  void markNotificationAsUnread(String id) {
    final notifications = _getCurrentUserData()?.notifications;
    if (notifications != null) {
      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        notifications[index].isRead = false;
        notifyListeners();
      }
    }
  }

  Future<void> addPost(String text, {File? image}) async {
    if (_currentUser == null) return;

    String? imageUrl;
    if (image != null) {
      // In a real app, you would upload the image to cloud storage and get the URL.
      // For this mock implementation, we'll copy it to the app's documents directory
      // and store the local file path.
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'post_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newImagePath = '${directory.path}/$fileName';
      await image.copy(newImagePath);
      imageUrl = newImagePath;
    }

    final newPost = PostModel(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      authorId: _currentUser!.id,
      authorName: _currentUser!.name,
      authorProfilePictureUrl: _currentUser!.profilePicturePath,
      timestamp: DateTime.now(),
      text: text,
      imageUrl: imageUrl,
    );

    _arenaPosts.insert(0, newPost); // Insert at the beginning to show newest first
    notifyListeners();
  }

  List<PostModel> getArenaPosts() {
    // In a real app, you'd apply pagination here.
    // For now, just sort by most recent.
    _arenaPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return _arenaPosts;
  }

  CourseModel? getCourseFromCatalog(String courseId) {
    try {
      // Find a course in the main catalog by its ID.
      return getCourseCatalog().firstWhere((c) => c.id == courseId);
    } on StateError {
      return null; // Return null if not found
    }
  }

  /// Returns the list of available teachers from the mock user data.
  List<UserModel> getTeachers() => _mockUsers.values.where((user) => user.role == 'teacher').toList();

  // --- Course Management (Teacher) ---

  // This list acts as our master course catalog for the entire app.
  final List<CourseModel> _courseCatalog = [
    CourseModel(
      id: 'cat1',
      title: 'Complete Secondary School Chemistry',
      description: 'A comprehensive course covering the entire secondary school chemistry syllabus.',
      thumbnailUrl: 'https://media.istockphoto.com/id/469951129/photo/group-of-multi-ethnic-students-in-chemistry-lab.jpg?s=612x612&w=0&k=20&c=WbKS_5P0HrNGWXTmNifwjh6Dw0mzj_spghkbJYd9xnY=',
      tags: ['Chemistry', 'Secondary School', 'Science'],
      teacherName: 'Dr. Idris',
      hasGradedQuizzes: true,
      hasFinalExam: true,
      hasCertificate: true,
      certificatePassingGrade: 75,
      modules: [
        ModuleModel(
            id: 'mod1_1',
            title: 'Module 1: Fundamentals of Chemistry',
            submodules: [
              SubmoduleModel(id: 'sub1_1_1', title: 'Introduction to Chemistry', contentType: ContentType.youtubeVideo, contentUrl: 'https://www.youtube.com/watch?v=FSyA4_30O54', transcript: 'This is the transcript for the introduction to chemistry video.'),
              SubmoduleModel(id: 'sub1_1_2', title: 'States of Matter', contentType: ContentType.image, contentUrl: 'https://placehold.co/1280x720/74C7A3/000000/png?text=States+of+Matter', transcript: 'Solid, Liquid, Gas. These are the three main states of matter.'),
            ],
            quiz: QuizModel(id: 'quiz1_1', title: 'Fundamentals of Chemistry Quiz', questions: [
              QuestionModel(
                id: 'q1_1_1',
                text: 'What are the three main states of matter?',
                options: [
                  OptionModel(text: 'Solid, Liquid, Gas', isCorrect: true),
                  OptionModel(text: 'Solid, Liquid, Plasma'),
                  OptionModel(text: 'Fire, Water, Air'),
                ],
              ),
              QuestionModel(
                id: 'q1_1_2',
                text: 'Which of the following is a chemical property?',
                options: [
                  OptionModel(text: 'Color'),
                  OptionModel(text: 'Density'),
                  OptionModel(text: 'Flammability', isCorrect: true),
                ],
              ),
            ])),
        ModuleModel(id: 'mod1_2', title: 'Module 2: Chemical Reactions', submodules: [
          SubmoduleModel(id: 'sub1_2_1', title: 'Types of Reactions', contentType: ContentType.youtubeVideo, contentUrl: 'https://www.youtube.com/watch?v=i-r_i-j-E-4', transcript: 'Transcript for types of reactions.'),
          SubmoduleModel(id: 'sub1_2_2', title: 'Balancing Equations', contentType: ContentType.text, contentUrl: '', transcript: 'Balancing chemical equations is a fundamental skill in chemistry. It involves ensuring that the number of atoms of each element is the same on both the reactant and product sides of the equation, adhering to the law of conservation of mass.'),
        ]),
      ],
    ),
    CourseModel(
      id: 'cat2',
      title: 'Biology JAMB Course 2024',
      description: 'Ace your JAMB biology exam with our targeted lessons and quizzes.',
      thumbnailUrl: 'https://www.shutterstock.com/image-photo/science-laboratory-microscope-research-medical-260nw-2499118491.jpg',
      tags: ['Biology', 'JAMB', 'Science'],
      teacherName: 'Dr. Idris',
      hasGradedQuizzes: true,
      hasFinalExam: false,
      hasCertificate: false,
      modules: [
        ModuleModel(id: 'mod2_1', title: 'Module 1: Cell Biology', submodules: [
          SubmoduleModel(id: 'sub2_1_1', title: 'The Cell: Basic Unit of Life', contentType: ContentType.youtubeVideo, contentUrl: 'https://www.youtube.com/watch?v=8IlzKri08kk', transcript: 'Transcript for cell biology intro.'),
          SubmoduleModel(id: 'sub2_1_2', title: 'Cell Organelles', contentType: ContentType.image, contentUrl: 'https://placehold.co/1280x720/F07C3B/000000/png?text=Cell+Organelles', transcript: 'Transcript for cell organelles.'),
        ]),
      ],
    ),
    CourseModel(
      id: 'cat3',
      title: 'Mastering Newtonian Physics',
      description: 'From kinematics to dynamics, understand the fundamentals of classical mechanics.',
      thumbnailUrl: 'https://www.shutterstock.com/image-vector/physics-chalkboard-background-hand-drawn-260nw-1988419205.jpg',
      tags: ['Physics', 'Advanced', 'Science'],
      teacherName: 'Dr. Idris',
      hasGradedQuizzes: true,
      hasFinalExam: true,
      hasCertificate: true,
      certificatePassingGrade: 80,
      modules: [
        ModuleModel(id: 'mod3_1', title: 'Module 1: Kinematics', submodules: [
          SubmoduleModel(id: 'sub3_1_1', title: 'Motion in One Dimension', contentType: ContentType.youtubeVideo, contentUrl: 'https://www.youtube.com/watch?v=ZM8ECpBuQYE', transcript: 'Transcript for kinematics.'),
        ]),
      ],
    ),
    CourseModel(
      id: 'cat4',
      title: 'Calculus for Further Maths',
      description: 'A deep dive into differentiation and integration for advanced problem-solving.',
      thumbnailUrl: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?q=80&w=2070&auto=format&fit=crop',
      tags: ['Further Maths', 'Mathematics', 'Calculus', 'Advanced'],
      teacherName: 'Dr. Idris',
      hasGradedQuizzes: false,
      hasFinalExam: false,
      hasCertificate: false,
      modules: [
        ModuleModel(id: 'mod4_1', title: 'Module 1: Differentiation', submodules: [
          SubmoduleModel(id: 'sub4_1_1', title: 'Basic Differentiation Rules', contentType: ContentType.youtubeVideo, contentUrl: 'https://www.youtube.com/watch?v=5yfh5cf4-0w', transcript: 'Transcript for differentiation.'),
        ]),
      ],
    ),
  ];

  List<CourseModel> getCourseCatalog() => _courseCatalog;

  List<CourseModel> getCourseCatalogWithUserData() {
    if (!isLoggedIn) {
      return getCourseCatalog(); // Return plain catalog if not logged in
    }
    final catalog = getCourseCatalog();
    final userCourses = _getCurrentUserData()?.inProgressCourses ?? [];
    final userCoursesMap = {for (var c in userCourses) c.id: c};

    final result = catalog.map((catalogCourse) {
      if (userCoursesMap.containsKey(catalogCourse.id)) {
        // User is enrolled, return their specific course data
        return userCoursesMap[catalogCourse.id]!;
      } else {
        // User is not enrolled, return the catalog version with isEnrolled: false
        return catalogCourse.copyWith(isEnrolled: false);
      }
    }).toList();

    return result;
  }

  /// Adds a new course to the master catalog.
  Future<void> addCourse(CourseModel course) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network save
    _courseCatalog.add(course);
    notifyListeners(); // Notify listeners that the course list has changed.
  }

  /// Updates the details of an existing course in the master catalog.
  Future<void> updateCourseDetails(CourseModel updatedCourse) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network save
    final index = _courseCatalog.indexWhere((c) => c.id == updatedCourse.id);
    if (index != -1) {
      _courseCatalog[index] = updatedCourse;
      notifyListeners();
    }
  }

  /// Deletes a course from the master catalog and from all users' data.
  Future<void> deleteCourse(String courseId) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network save
    // Remove from the main catalog
    _courseCatalog.removeWhere((c) => c.id == courseId);

    // Also remove from any user's enrolled/recommended courses for data consistency
    for (var userData in _mockDatabase.values) {
      userData.inProgressCourses.removeWhere((c) => c.id == courseId);
    }
    notifyListeners();
  }

  /// Adds a new module to a specific course in the catalog.
  Future<void> addModuleToCourse(String courseId, String title) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network save
    final courseIndex = _courseCatalog.indexWhere((c) => c.id == courseId);
    if (courseIndex != -1) {
      final course = _courseCatalog[courseIndex];
      final moduleNumber = course.modules.length + 1;
      final newModule = ModuleModel(
        id: 'mod_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Module $moduleNumber: $title', // Automatically prefix the title
        submodules: [],
      );
      course.modules.add(newModule);
      notifyListeners(); // Notify listeners that the course has been updated.
    }
  }

  /// Updates the order of modules in a course.
  Future<void> updateModuleOrder(String courseId, List<ModuleModel> reorderedModules) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network save
    final course = getCourseFromCatalog(courseId);
    if (course != null) {
      // We cannot reassign the final 'modules' list.
      // Instead, we clear the existing list and add the reordered items.
      course.modules..clear()..addAll(reorderedModules);
      notifyListeners(); // Notify listeners that the course has been updated.
    }
  }

  /// Updates the title of a specific module.
  Future<void> updateModuleTitle(String courseId, String moduleId, String newTitle) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network save
    final course = getCourseFromCatalog(courseId);
    if (course != null) {
      final moduleIndex = course.modules.indexWhere((m) => m.id == moduleId);
      if (moduleIndex != -1) {
        // Create a new module with the updated title but same submodules
        final updatedModule = course.modules[moduleIndex].copyWith(title: newTitle);
        // Replace the old module with the updated one
        course.modules[moduleIndex] = updatedModule;
        notifyListeners();
      }
    }
  }

  /// Adds or updates the quiz for a specific module.
  Future<void> addOrUpdateQuizForModule(String courseId, String moduleId, QuizModel quiz) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network save
    final module = getModuleFromCourse(courseId, moduleId);
    if (module != null) {
      final course = getCourseFromCatalog(courseId)!;
      final moduleIndex = course.modules.indexWhere((m) => m.id == moduleId);
      course.modules[moduleIndex] = module.copyWith(quiz: quiz);
      notifyListeners();
    }
  }

  /// Deletes the quiz from a specific module.
  Future<void> deleteQuizFromModule(String courseId, String moduleId) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network save
    final module = getModuleFromCourse(courseId, moduleId);
    if (module != null && module.quiz != null) {
      // copyWith doesn't handle setting a value to null well, so we create a new instance.
      final course = getCourseFromCatalog(courseId)!;
      final moduleIndex = course.modules.indexWhere((m) => m.id == moduleId);
      course.modules[moduleIndex] = ModuleModel(id: module.id, title: module.title, submodules: module.submodules, quiz: null);
      notifyListeners();
    }
  }

  // --- Quiz Progress Methods ---

  /// Saves a student's quiz attempt.
  void saveQuizAttempt(String courseId, String moduleId, int score, int totalQuestions, Map<int, int> selectedAnswers) {
    final userData = _getCurrentUserData();
    final module = getModuleFromCourse(courseId, moduleId);
    if (userData == null || module?.quiz == null) return;

    final newAttempt = QuizAttemptModel(
      quizId: module!.quiz!.id,
      timestamp: DateTime.now(),
      score: score,
      totalQuestions: totalQuestions,
      selectedAnswers: selectedAnswers,
    );

    userData.quizAttempts.add(newAttempt);
    notifyListeners();
  }

  /// Retrieves all attempts for a specific quiz, sorted by most recent first.
  List<QuizAttemptModel> getQuizAttemptsForModule(String courseId, String moduleId) {
    final userData = _getCurrentUserData();
    final module = getModuleFromCourse(courseId, moduleId);
    if (userData == null || module?.quiz == null) return [];

    return userData.quizAttempts.where((attempt) => attempt.quizId == module!.quiz!.id).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Updates the title of a specific submodule.
  Future<void> updateSubmoduleTitle(String courseId, String moduleId, String submoduleId, String newTitle) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network save
    final module = getModuleFromCourse(courseId, moduleId);
    if (module != null) {
      final submoduleIndex = module.submodules.indexWhere((s) => s.id == submoduleId);
      if (submoduleIndex != -1) {
        final originalSubmodule = module.submodules[submoduleIndex];
        final updatedSubmodule = originalSubmodule.copyWith(
          title: newTitle,
          transcript: originalSubmodule.transcript, // Pass existing transcript as it's required
        );
        module.submodules[submoduleIndex] = updatedSubmodule;
        notifyListeners();
      }
    }
  }

  /// Deletes a module from a course.
  Future<void> deleteModule(String courseId, String moduleId) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network save
    final course = getCourseFromCatalog(courseId);
    if (course != null) {
      course.modules.removeWhere((module) => module.id == moduleId);
      notifyListeners();
    }
  }

  ModuleModel? getModuleFromCourse(String courseId, String moduleId) {
    final course = getCourseFromCatalog(courseId);
    if (course == null) return null;
    try {
      // Find a module within the specific course by its ID.
      return course.modules.firstWhere((m) => m.id == moduleId);
    } on StateError {
      return null; // Return null if not found
    }
  }

  /// Adds a new submodule to a specific module within a course.
  Future<void> addSubmoduleToModule(String courseId, String moduleId, String title, String transcript, ContentType contentType, String contentUrl) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network save
    final module = getModuleFromCourse(courseId, moduleId);
    if (module != null) {
      final submoduleNumber = module.submodules.length + 1;
      final newSubmodule = SubmoduleModel(
        id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Lesson $submoduleNumber: $title', // Automatically prefix the title
        transcript: transcript,
        contentType: contentType,
        contentUrl: contentUrl,
      );
      module.submodules.add(newSubmodule);
      notifyListeners();
    }
  }

  /// Deletes a submodule from a module.
  Future<void> deleteSubmodule(String courseId, String moduleId, String submoduleId) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network save
    final module = getModuleFromCourse(courseId, moduleId);
    if (module != null) {
      module.submodules.removeWhere((submodule) => submodule.id == submoduleId);
      notifyListeners();
    }
  }

  /// Updates an existing submodule within a course.
  Future<void> updateSubmodule(String courseId, String moduleId, SubmoduleModel updatedSubmodule) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network save
    final module = getModuleFromCourse(courseId, moduleId);
    if (module != null) {
      final submoduleIndex = module.submodules.indexWhere((s) => s.id == updatedSubmodule.id);
      if (submoduleIndex != -1) {
        module.submodules[submoduleIndex] = updatedSubmodule;
        notifyListeners();
      }
    }
  }

  /// Updates the order of submodules in a module.
  Future<void> updateSubmoduleOrder(String courseId, String moduleId, List<SubmoduleModel> reorderedSubmodules) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network save
    final module = getModuleFromCourse(courseId, moduleId);
    if (module != null) {
      // We cannot reassign the final 'submodules' list.
      // Instead, we clear the existing list and add the reordered items.
      module.submodules..clear()..addAll(reorderedSubmodules);
      notifyListeners(); // Notify listeners that the module has been updated.
    }
  }

  SubmoduleModel? getSubmodule(String courseId, String moduleId, String submoduleId) {
    final module = getModuleFromCourse(courseId, moduleId);
    if (module == null) return null;
    try {
      return module.submodules.firstWhere((s) => s.id == submoduleId);
    } on StateError {
      return null;
    }
  }

  // --- Course Enrollment & Progress Methods ---

  // Checks if a user is enrolled in a specific course
  bool isEnrolled(String courseId) {
    final userData = _getCurrentUserData();
    if (userData == null) return false;
    return userData.inProgressCourses.any((course) => course.id == courseId);
  }

  // Enrolls a user in a course
  void enrollInCourse(CourseModel course) {
    final userData = _getCurrentUserData();
    if (userData == null || isEnrolled(course.id)) return;

    // Create a user-specific copy of the course with initial progress
    final newCourse = course.copyWith(
      isEnrolled: true,
      progress: 0.0,
      lastAccessedSubmoduleId: null, // User hasn't accessed any submodule yet.
      modules: course.modules.map((module) => module.copyWith(
        title: module.title, // Pass the existing title as it's required
        submodules: module.submodules.map((sub) => sub.copyWith(isCompleted: false, title: sub.title, transcript: sub.transcript)).toList(),
      )).toList(),
    );

    userData.inProgressCourses.add(newCourse);
    notifyListeners();
  }

  // Updates the completion status of a submodule and recalculates course progress
  void updateSubmoduleCompletion(String courseId, String submoduleId, bool completed) {
    final userData = _getCurrentUserData();
    if (userData == null) return;

    final courseIndex = userData.inProgressCourses.indexWhere((c) => c.id == courseId);
    if (courseIndex == -1) return;

    final course = userData.inProgressCourses[courseIndex];
    int totalSubmodules = 0;
    int completedSubmodules = 0;

    final updatedModules = course.modules.map((module) {
      return module.copyWith(
        title: module.title, // Pass the existing title as it's required
        submodules: module.submodules.map((submodule) {
          totalSubmodules++;
          if (submodule.id == submoduleId) {
            final updatedSubmodule = submodule.copyWith(isCompleted: completed, title: submodule.title, transcript: submodule.transcript);
            if (updatedSubmodule.isCompleted) completedSubmodules++;
            return updatedSubmodule;
          }
          if (submodule.isCompleted) completedSubmodules++;
          return submodule;
        }).toList(),
      );
    }).toList();

    final newProgress = totalSubmodules > 0 ? completedSubmodules / totalSubmodules : 0.0;

    // Update the course in the user's inProgressCourses list
    userData.inProgressCourses[courseIndex] = course.copyWith(
      progress: newProgress,
      modules: updatedModules,
      // Optionally update lastAccessed here if needed
    );
    notifyListeners();
  }

  /// Updates the last accessed submodule for a given course.
  void updateLastAccessedSubmodule(String courseId, String submoduleId) {
    final userData = _getCurrentUserData();
    if (userData == null) return;

    final courseIndex = userData.inProgressCourses.indexWhere((c) => c.id == courseId);
    if (courseIndex != -1) {
      final course = userData.inProgressCourses[courseIndex];
      // Only update if it's different to avoid unnecessary rebuilds.
      if (course.lastAccessedSubmoduleId != submoduleId) {
        userData.inProgressCourses[courseIndex] = course.copyWith(lastAccessedSubmoduleId: submoduleId);
        notifyListeners();
      }
    }
  }

  // Retrieves a specific course with user-specific progress
  CourseModel? getUserCourse(String courseId) {
    final userData = _getCurrentUserData();
    if (userData == null) return null;

    // Get the master course from the catalog as the source of truth for content.
    final masterCourse = getCourseFromCatalog(courseId);
    if (masterCourse == null) return null; // Course may have been deleted.

    try {
      // Get the user's current (potentially outdated) version of the course.
      final userCourse = userData.inProgressCourses.firstWhere((c) => c.id == courseId);

      // --- SYNC LOGIC ---
      // Create a map of the user's submodule completion status for quick lookup.
      final Map<String, bool> userProgressMap = {};
      for (final module in userCourse.modules) {
        for (final submodule in module.submodules) {
          userProgressMap[submodule.id] = submodule.isCompleted;
        }
      }

      // Rebuild the modules list from the master catalog, applying the user's progress.
      final syncedModules = masterCourse.modules.map((masterModule) {
        return masterModule.copyWith(
          title: masterModule.title, // Pass title as it appears to be required by ModuleModel.copyWith
          submodules: masterModule.submodules.map((masterSubmodule) {
            // Apply the user's saved progress to the master submodule structure.
            return masterSubmodule.copyWith(
              isCompleted: userProgressMap[masterSubmodule.id] ?? false,
            );
          }).toList(),
        );
      }).toList();

      // Recalculate progress based on the newly synced data.
      final totalSubmodules = syncedModules.fold<int>(0, (sum, module) => sum + module.submodules.length);
      final completedSubmodules = syncedModules.fold<int>(0, (sum, module) => sum + module.submodules.where((s) => s.isCompleted).length);
      final newProgress = totalSubmodules > 0 ? completedSubmodules / totalSubmodules : 0.0;

      // Create the final, synced course object.
      final syncedCourse = masterCourse.copyWith(
        isEnrolled: true,
        progress: newProgress,
        lastAccessedSubmoduleId: userCourse.lastAccessedSubmoduleId, // Keep the user's last accessed lesson
        modules: syncedModules,
      );

      // Persist the synced course back to the user's data for future use.
      final courseIndex = userData.inProgressCourses.indexWhere((c) => c.id == courseId);
      userData.inProgressCourses[courseIndex] = syncedCourse;

      return syncedCourse;
    } on StateError {
      return null; // Return null if the course isn't in the user's list.
    }
  }

  // Finds the next submodule in a course
  SubmoduleModel? getNextSubmodule(String courseId, String currentSubmoduleId) {
    final course = getUserCourse(courseId);
    if (course == null) return null;

    bool foundCurrent = false;
    for (final module in course.modules) {
      for (final submodule in module.submodules) {
        if (foundCurrent) {
          return submodule; // This is the next one
        }
        if (submodule.id == currentSubmoduleId) {
          foundCurrent = true;
        }
      }
    }
    return null; // No next submodule
  }

  // Finds the previous submodule in a course
  SubmoduleModel? getPreviousSubmodule(String courseId, String currentSubmoduleId) {
    final course = getUserCourse(courseId);
    if (course == null) return null;

    SubmoduleModel? previousSubmodule;
    for (final module in course.modules) {
      for (final submodule in module.submodules) {
        if (submodule.id == currentSubmoduleId) {
          return previousSubmodule; // Return the one found before the current
        }
        previousSubmodule = submodule;
      }
    }
    return null; // No previous submodule
  }

  // --- Support Chat Methods ---

  void resetSupportChat() {
    final userData = _getCurrentUserData();
    if (userData == null) return;

    // Clear the history and add the initial welcome message back.
    userData.supportChatHistory.clear();
    userData.supportChatHistory.add(
      ChatMessageModel(
          id: 'msg_reset_${DateTime.now().millisecondsSinceEpoch}', text: 'Hello! I am the Idris Academy support bot. How can I help you today? You can ask me about navigating the app, finding courses, or checking your progress.', timestamp: DateTime.now(), isSentByUser: false),
    );
    notifyListeners();
  }

  List<ChatMessageModel> getSupportChatHistory() => _getCurrentUserData()?.supportChatHistory ?? [];

  Future<void> sendSupportMessage(String text) async {
    final userData = _getCurrentUserData();
    if (userData == null) return;

    // Add user's message
    final userMessage = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      timestamp: DateTime.now(),
      isSentByUser: true,
    );
    userData.supportChatHistory.add(userMessage);
    notifyListeners();

    // Simulate bot thinking
    await Future.delayed(const Duration(milliseconds: 1500));

    // Generate bot response
    final botResponseText = _getBotResponse(text);
    final botMessage = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: botResponseText,
      timestamp: DateTime.now(),
      isSentByUser: false,
    );
    userData.supportChatHistory.add(botMessage);
    notifyListeners();
  }

  String _getBotResponse(String userText) {
    // This is where you would integrate with Gemini Flash.
    // For now, a simple rule-based response.
    final text = userText.toLowerCase();
    if (text.contains('hello') || text.contains('hi')) {
      return 'Hello there! How can I assist you today?';
    } else if (text.contains('course')) {
      return 'You can find all available courses by tapping the "Courses" tab at the bottom of the screen. From there, you can filter by category.';
    } else if (text.contains('progress') || text.contains('dashboard')) {
      return 'Your dashboard shows your in-progress courses and achievements. Tap the "Dashboard" icon in the bottom navigation bar to see it.';
    } else if (text.contains('profile')) {
      return 'The "Profile" tab contains your detailed stats and account settings.';
    }
    return "I'm here to help you navigate the Idris Academy app. You can ask me how to find courses, check your progress, or manage your profile.";
  }
}
