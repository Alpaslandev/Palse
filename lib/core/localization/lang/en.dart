// English language file
const Map<String, String> en = {
  // General
  'app_name': 'Palse App',

  // Login/Register
  'login': 'Login',
  'register': 'Register',
  'email': 'Email',
  'password': 'Password',
  'confirm_password': 'Confirm Password',
  'forgot_password': 'Forgot Password',
  'continue': 'Continue',
  'welcome_message': 'Welcome 👋',
  'or': 'Or',
  'login_successful': 'Login successful',
  'login_failed': 'Login failed',
  'privacy_terms_agreement':
      'By logging in, you agree to the Privacy Policy and Terms of Use.',
  'create_account': 'Create Account',
  'login_subtitle': 'Log in to your account or continue with social media',
  'signup_subtitle': 'Create a new account and join events',
  'email_hint': 'Enter your email address',
  'password_hint': 'Enter your password',
  'confirm_password_hint': 'Enter your password again',
  'login_with_email': 'Login with Email',
  'signup_with_email': 'Sign up with Email',
  'social_login_title': 'Login with Social Media',
  'google_login': 'Google',
  'apple_login': 'Apple',
  'already_have_account': 'Already have an account?',
  'dont_have_account': 'Don\'t have an account?',
  'passwords_dont_match': 'Passwords don\'t match',
  'by_continuing': 'By continuing',
  'and': 'and',

  // Profile Setup
  'profile_setup': 'Create Profile',
  'profile_setup_step': 'Step {step}/6',
  'profile_setup_back': 'Back',
  'profile_setup_next': 'Next',
  'profile_setup_finish': 'Finish',
  'profile_setup_error_name':
      'Please enter your name and surname correctly (at least 3 characters)',
  'profile_setup_error_birthday_gender':
      'Please select your birth date and gender',
  'profile_setup_error_location':
      'Please select a location or use your current location',
  'profile_setup_error_nickname':
      'Please enter a valid nickname (at least 3 characters)',
  'profile_setup_error_categories': 'Please select at least 3 categories',

  // Profile Setup Steps
  // Step 1: User Info
  'user_info_welcome': 'Welcome!',
  'user_info_description': 'We need a few details to prepare your experience.',
  'user_info_first_name': 'First Name',
  'user_info_last_name': 'Last Name',
  'user_info_first_name_hint': 'Enter your first name',
  'user_info_last_name_hint': 'Enter your last name',
  'user_info_perfect': 'Perfect!',
  'user_info_hello':
      'Hello {firstName} {lastName}, now you can proceed to the next steps.',
  'user_info_info': 'Information',
  'user_info_please_enter':
      'Please enter your first and last name. This information will appear on your profile.',

  // Step 2: Birthday and Gender
  'birthday_gender_title': 'Let\'s get to know you',
  'birthday_gender_birthday': 'Date of Birth',
  'birthday_gender_select_date': 'Select Date',
  'birthday_gender_age_restriction':
      'You must be at least 18 years old to use this app',
  'birthday_gender_gender': 'Gender',
  'birthday_gender_male': 'Male',
  'birthday_gender_female': 'Female',
  'birthday_gender_other': 'Other',
  'birthday_gender_required': 'Required',
  'birthday_gender_optional': 'Optional',
  'birthday_gender_optional_info':
      'Date of birth and gender information are optional. You can update them later in profile settings if you wish.',
  'birthday_gender_select_birth_date': 'Please select your birth date',
  'birthday_gender_select_gender': 'Please select your gender',
  'birthday_gender_awesome': 'Awesome!',
  'birthday_gender_basics_completed':
      'Your basic information is complete, now you can proceed to the next steps.',
  'birthday_gender_info': 'Information',
  'birthday_gender_info_text':
      'Your birth date and gender will be used to recommend suitable events for you.',

  // Step 3: Location
  'location_title': 'Your Location',
  'location_description': 'We\'ll show you events and activities near you',
  'location_current': 'Use Current Location',
  'location_search': 'Search',
  'location_search_hint': 'Search city, district, etc.',
  'location_permission_text':
      'Allow location permission to find events near you',
  'location_permission_button': 'Grant Location Permission',
  'location_required': 'Required',
  'location_optional': 'Optional',
  'location_optional_info':
      'Location information is optional. You can update it later in profile settings if you wish.',
  'location_please_select': 'Please select a location',
  'location_search_label': 'Search Location',
  'location_search_hint_detailed': 'Enter city or district name',
  'location_selected': 'Selected Location:',
  'location_coordinates': 'Coordinates: {lat}, {lng}',
  'location_error_getting': 'Could not get location: {error}',
  'location_error_general': 'Error: {error}',

  // Step 4: Nickname
  'nickname_title': 'Choose a Nickname',
  'nickname_description': 'Other users will see you like this',
  'nickname_hint': 'Enter a nickname (at least 3 characters)',
  'nickname_availability_checking': 'Checking availability...',
  'nickname_available': 'This nickname is available',
  'nickname_unavailable': 'This nickname is already taken',
  'nickname_almost_done': 'Almost done...',
  'nickname_choose_cool': 'How about a cool username?',
  'nickname_required': 'Required',
  'nickname_profile_info': 'This name will appear on your profile',
  'nickname_label': 'Nickname',
  'nickname_min_length_error': 'Nickname must be at least 3 characters',
  'nickname_please_enter': 'Please enter a nickname',
  'nickname_great_choice': 'Great choice!',
  'nickname_tip': 'Choose a fun and unique name!',

  // Step 5: Profile Picture
  'profile_picture_title': 'Add Profile Picture',
  'profile_picture_description': 'This helps others recognize you',
  'profile_picture_upload': 'Upload Photo',
  'profile_picture_take': 'Take Photo',
  'profile_picture_skip': 'Skip for Now',
  'profile_picture_almost_done': 'Almost Done!',
  'profile_picture_add_photo':
      'Would you like to add a photo to help us recognize you?',
  'profile_picture_tip':
      'Users with profile pictures get 70% more interactions!',
  'profile_picture_add': 'Add Photo',
  'profile_picture_looks_great':
      'Looks great! You can tap again if you want to change your photo.',
  'profile_picture_skip_info':
      'You can skip this step and add a photo later in profile settings',

  // Step 6: Categories
  'categories_title': 'Select Your Interests',
  'categories_description':
      'Select at least 3 categories you\'re interested in',
  'categories_min_selection': 'Select {count} more categories',
  'categories_selected': '{count} categories selected',
  'categories_finally': 'Finally',
  'categories_select_interests': 'select your interests',
  'categories_great': 'Great! You\'ve selected enough categories',
  'categories_min_required': 'You need to select at least 3 categories',
  'categories_list_title': 'Categories',

  // Home
  'home': 'Home',
  'explore': 'Explore',
  'messages': 'Messages',
  'profile': 'Profile',
  'city_based': 'City Based',
  'interest_based': 'By Interest',
  'other': 'Other',
  'favorites': 'Favorites',
  'no_listings_yet': 'No listings yet',
  'no_listings_in_your_city': 'No listings found in your city',
  'no_listings_in_your_interests': 'No listings found in your interests',
  'no_more_listings_in_category': 'No more listings in this category.',
  'click_to_see_other_listings': 'Click to see other listings',
  'create_listing': 'Create Listing',

  // Messages
  'no_messages': 'No messages yet',
  'type_message': 'Type a message...',
  'send': 'Send',
  'quote': 'Quote',
  'error_occurred': 'An error occurred',
  'no_notifications': 'No notifications found',
  'camera': 'Camera',
  'gallery': 'Gallery',

  // Listings and Profile
  'my_listings': 'My Listings',
  'my_likes': 'My Likes',
  'profile_viewers': 'Profile Viewers',
  'no_listing_found': 'No listing found',
  'show_less': 'Show less',
  'show_more': 'Show more...',
  'likers': 'Likers',
  'delete': 'Delete',
  'like': 'Like',
  'join': 'Join',
  'waiting': 'Waiting',
  'joined': 'Joined',
  'join_request': 'Join Requests',
  'message': 'Message',
  'report_listing': 'Report Listing',
  'report_sent': 'Report has been initiated',
  'block_user': 'Block This User',
  'user_blocked': 'User blocked',
  'unblock_user': 'Unblock User',
  'user_unblocked': 'User unblocked',
  'user_blocked_message':
      'You have blocked this user. You need to unblock them to send messages.',
  'listings': 'Listings',
  'send_message': 'Send Message',
  'report_abuse': 'Report Abuse',
  'comments': 'Comments',
  'add_comment': 'Add Comment',
  'advert_deleted_successfully': 'Listing successfully deleted',
  // Create Advert
  'create_advert': 'Create Advert',
  'event_type': 'Event Type',
  'event_description': 'Event Description',
  'event_date': 'Event Date',
  'event_location': 'Event Location',
  'please_select_event_date': 'Please select an event date',
  'please_select_event_location': 'Please select an event location',
  'event_title': 'Event Title',
  'event_title_required': 'Event title is required',
  'event_title_min_length': 'Event title must be at least 15 characters',
  'event_description_required': 'Event description is required',
  'event_description_min_length':
      'Event description must be at least 15 characters',
  'event_type_required': 'Please select an event type',
  'only_premium_users_can_select_photo':
      'Only premium users can select a photo',
  'premium_subscription': 'Premium Subscription',
  'select_photo': 'Select Photo',
  'use_ready_photo': 'Use Ready Photo',
  'finish': 'Finish',
  'back': 'Back',
  'advert_created_successfully_non_premium':
      'You can now create ads without ads by subscribing to premium.',
  'advert_created_successfully_premium':
      'Your advert has been created successfully.',
  'please_select_photo': 'Please select a photo',
  // Profile
  'edit_profile': 'Edit Profile',
  'settings': 'Settings',
  'logout': 'Logout',
  'daily_task': 'Daily Task',
  'daily_task_step1': 'Create a listing and send a message!',
  'daily_task_step2': 'Complete the task, earn +100 XP in total!',
  'complete_task': 'Complete Task',
  'verify_profile_text':
      'Verify that you are a real profile and\ngain extra visibility!',

  // Categories
  'categories': 'Categories',
  'save': 'Save',
  'my_interests': 'My Interests',
  'all_categories': 'All Categories',
  'interests_saved': 'Your interests have been saved',

  // XP System
  'xp_system': 'XP System and Rewards',
  'ranks': 'Ranks',
  'ranks_description': 'Your rank increases based on the XP points you earn:',

  // Premium
  'get_premium': 'Get Premium',
  'premium_required': 'Premium Membership Required',
  'premium_photo_message': 'Get premium membership to send photos.',
  'ok': 'OK',

  // Error Messages
  'error': 'Error',
  'try_again': 'Try Again',
  'connection_error': 'Connection error',
  'min_categories_warning': 'You must select at least 3 categories.',
  // XP Event Groups
  'welcome_rewards': 'Welcome Rewards (One-time)',
  'listing': 'Listing',
  'messaging': 'Messaging',
  'commenting': 'Comments',
  'daily_tasks': 'Daily Tasks',

  // XP Event Descriptions
  'first_listing_description': 'Create your first listing',
  'first_message_description': 'Send your first message',
  'create_listing_description': 'Create a new listing',
  'receive_first_message_description': 'Each first message to your listing',
  'send_first_message_description': 'Per user you message for the first time',
  'write_comment_description': 'Write a comment to someone',
  'receive_comment_description': 'Receive a comment on your profile',
  'daily_task_listing_and_message_description':
      'Create a listing and send a message',
  'daily_login_description': 'Daily login to the app',
  'daily_create_listing_description': 'Create a listing',
  'daily_send_message_description': 'Send a message',
  'no_daily_task_yet': 'No daily task yet',
  'daily_task_completed': 'Daily task completed! You earned +100 XP',
  'task_completed': 'Task Completed',
  'next_reset': 'Next reset',
  'completed_tasks': 'Completed tasks',
  'daily_task_login': 'Log in to the app',
  'daily_task_create_listing': 'Create a listing',
  'daily_task_send_message': 'Send a message',
  'notification_daily_tasks_reset_title': 'Daily Tasks Reset',
  'notification_daily_tasks_reset_body':
      'New daily tasks are ready! Complete them and earn XP.',
  'notification_xp_reset_title': 'XP Reset',
  'notification_xp_reset_body':
      'Your XP has been reset. You can start earning XP again.',

  // Reward Notifications
  'comment_reward_earned': 'You earned +{xp} XP for writing a comment!',
  'comment_error': 'An error occurred while adding the comment',
  'comment_received_title': 'New Comment Received!',
  'comment_received_body':
      '{commenter} commented on your profile and you earned +{xp} XP!',

  // Language Settings
  'language_settings': 'Language Settings',
  'language_change_info':
      'Language changes are applied immediately and saved automatically.',
  'app_language': 'App Language',

  // Settings Page
  'user': 'User',
  'application': 'Application',
  'general': 'General',
  'dark_theme': 'Dark Theme',
  'notifications': 'Notifications',
  'account_verified': 'Account Verified',
  'account_not_verified': 'Account Not Verified',
  'faq': 'Frequently Asked Questions',
  'terms_of_use': 'Terms of Use',
  'privacy_policy': 'Privacy Policy',
  'about_us': 'About Us',
  'app_version': 'App Version',

  // Premium Overlay
  'premium_feature_only': 'This feature is only for premium subscribers',

  // Profile Editing
  'change_photo': 'Change Photo',
  'username': 'Username',
  'first_name': 'First Name',
  'last_name': 'Last Name',
  'phone': 'Phone',
  'location': 'Location',
  'birth_date': 'Birth Date',
  'gender': 'Gender',
  'phone_verified': 'Phone Verified.',
  'phone_not_verified': 'Phone Not Verified.',
  'phone_verification_success': 'Phone number successfully verified',
  'photo_upload_error': 'Photo upload error',
  'profile_updated_successfully': 'Profile updated successfully',
  'delete_account': 'Delete Account',
  'delete_account_confirmation':
      'Are you sure you want to delete your account? This action cannot be undone.',
  // Leaderboard
  'leaderboard': 'Leaderboard',
  'your_rank': 'Your Rank',

  // XP Progress
  'to_next_level_part1': 'To next level: ',
  'to_next_level_part2': ' remaining!',
  'to_next_premium_part1': 'To next premium reward: ',
  'to_next_premium_part2': ' remaining!',
  'total_xp': 'Total XP',
  'premium_rewards': 'Premium Rewards',
  'next_reward': 'Next Reward',
  'max_level_reached': 'Max level reached',
  'next_level': 'Next Level',
  // Filtering
  'filtering': 'Filtering',
  'distance': 'Distance',
  'male': 'Male',
  'female': 'Female',
  'all': 'All',
  'category': 'Category',
  'apply': 'Apply',

  // Success Notifications
  'notification_task_completed_title': 'New Task Completed!',
  'notification_task_completed_body':
      'You have completed the {task} task and earned {xp} XP.',
  'notification_xp_earned_title': 'XP Earned!',
  'notification_xp_earned_body':
      'You have earned {xp} XP from the {task} task.',
  'notification_rank_up_title': 'New Level!',
  'notification_rank_up_body':
      'Congratulations! You have reached {xp} XP and are now a {rank} {icon}! Explore more and take a step closer to leadership!',
  'notification_premium_reward_title': 'Premium Reward Earned!',
  'notification_premium_reward_body':
      'Congratulations! You have reached {xp} XP and earned 1 Week Premium Membership! Enjoy! 🎉',
  'notification_next_premium_title': 'No Stopping!',
  'notification_next_premium_body':
      'Only {xp} XP left for the next premium reward! Create an ad and send a message!',
  'notification_daily_task_reset_title': 'Daily Tasks Reset',
  'notification_daily_task_reset_body':
      'Daily tasks have been reset. You can start earning XP by completing new tasks.',

  // Categories - Enum translations
  'category_coffee_chat': 'Coffee & Chat',
  'category_book_meetings': 'Book Meetups',
  'category_language_culture': 'Language & Culture Exchange',
  'category_sports': 'Sports Activities',
  'category_football': 'Football Activities',
  'category_nature': 'Nature Activities',
  'category_fitness': 'Fitness & Exercise',
  'category_art_history': 'Art & Historical Tours',
  'category_movies_series': 'Movie & Series Meetups',
  'category_dance': 'Dance Meetups',
  'category_music': 'Music Activities',
  'category_concerts': 'Concert Meetups',
  'category_party': 'Parties & Entertainment',
  'category_culinary': 'Culinary Arts',
  'category_education': 'Educational Activities',
  'category_research': 'Research Groups',
  'category_video_games': 'Video Game Meetups',
  'category_crafts': 'Crafts & Handmade',
  'category_coding': 'Coding Meetups',
  'category_yoga': 'Yoga & Meditation',
  'category_photography': 'Photography Activities',
  'category_pets': 'Pet Meetups',
  'category_motorcycle': 'Motorcycle Groups',
  'category_cars': 'Car Groups',
  'category_fashion': 'Fashion & Clothing',
  'category_online': 'Online Events',
  'category_game_tournaments': 'Online Game Tournaments',
  'category_travel': 'Travel Activities',
  'category_room_sharing': 'Room Sharing & Real Estate',
  'category_car_rental': 'Car Rental & Trading',
  'category_items_trade': 'Item Trading',
  'category_theater': 'Theater & Cinema',
  'category_other': 'Other',

  // Gender
  'gender_male': 'Male',
  'gender_female': 'Female',
  'gender_others': 'Others',

  // Rank translations
  'rank_beginner': 'Discovery Beginner',
  'rank_explorer': 'Social Explorer',
  'rank_connector': 'Connection Master',
  'rank_leader': 'Event Leader',
  'rank_master': 'Social Master',

  // Location Page
  'location_search_city_district': 'Search City, District',
  'location_use_current': 'Use My Current Location',

  // Profile - Daily Task
  'daily_task_next_reset_time': '24 hours',
  'daily_tasks_reset_success':
      'Daily tasks reset! You can now complete new tasks.',

  // Reporting
  'please_explain_reason': 'Please explain your reason for reporting',
  'report_reason_hint': 'Type your report reason here...',
  'submit': 'Submit',
  'cancel': 'Cancel',

  // Chat
  'chats': 'Chats',
  'no_chats_yet': 'No chats yet',
  'delete_chat': 'Delete Chat',
  'delete_chat_confirmation': 'Are you sure you want to delete this chat?',
  'chat_deleted': 'Chat deleted successfully',
  'user_not_found': 'User not found',

  // Comment Reporting
  'comment_reported_success': 'Comment reported successfully',
  'comment_report_error': 'An error occurred while reporting the comment',

  // Phone Verification
  'phone_verification': 'Phone Verification',
  'login_required': 'You need to login first',
  'verify_your_phone': 'Verify Your Phone Number',
  'verify_phone_subtitle': 'Verify your phone number to secure your account',
  'phone_number': 'Phone Number',
  'phone_number_hint': '5XX XXX XX XX',
  'phone_number_info': 'Please enter without leading 0 (e.g. 5XX XXX XX XX)',
  'send_verification_code': 'Send Verification Code',
  'sending': 'Sending...',
  'info': 'Information',
  'sms_delay_info':
      'The SMS code may take a moment to arrive. Please wait at least 2 minutes.',
  'check_number_retry':
      'If you don\'t receive the code, check your number and try again.',
  'enter_verification_code': 'Enter Verification Code',
  'enter_6_digit_code': 'Enter the 6-digit code sent to your phone',
  'code_sent_to': 'Code sent to {phoneNumber}',
  'verification_code': 'Verification Code',
  'verification_code_hint': '6-digit code',
  'verify': 'Verify',
  'verifying': 'Verifying...',
  'resend_code': 'Resend Code',
  'important': 'Important',
  'verification_in_progress':
      'Please don\'t leave the app while verification is in progress.',
  'resend_code_info':
      'If you didn\'t receive the code, you can click "Resend Code".',
  'verification_error': 'Verification error occurred',
  'invalid_phone_format': 'Invalid phone number format',
  'too_many_requests': 'Too many requests sent. Please try again later',
  'quota_exceeded': 'SMS quota exceeded. Please try again later',
  'captcha_failed': 'Captcha verification failed. Please try again',
  'app_not_authorized': 'App is not authorized to use Firebase Authentication',
  'understood': 'UNDERSTOOD',
  'code_sent': 'Verification code sent',
  'please_enter_code': 'Please enter the verification code',
  'verification_id_not_found': 'Verification ID not found. Please try again.',
  'user_session_not_found': 'User session not found',
  'phone_verified_success': 'Phone number successfully verified',
  'phone_already_verified': 'Phone number is already verified',
  'error_prefix': 'Error: ',
  'please_enter_phone': 'Please enter your phone number',
  'invalid_characters':
      'Contains invalid characters (use only numbers, + and spaces)',
  'phone_too_short': 'Phone number is too short',
  'verification_in_progress_enter_code':
      'Verification in progress. Please enter the code or complete the process.',

  // Comment System
  'please_select_rating': 'Please select a rating',
  'please_write_comment': 'Please write a comment',
  'profile_evaluation': 'Profile Evaluation',
  'max_50_characters': 'You can enter up to 50 characters!',
  'write_your_comment': 'Write your comment...',
  'share': 'Share',
  'no_comments_yet': 'No comments yet',
  'viewmodel_comments_debug': 'Comments',
  'received_comment_debug': 'Received comment',
  'comment_not_added_debug': 'Comment not added',

  // XP Card
  'rank': 'Rank',
  'level_progress': 'Level Progress',
  'to_next_level': 'To next level',
  'earned_premium_rewards': 'Earned Premium Rewards',
  'to_next_premium': 'To next premium reward',
  'premium_thresholds': 'Premium Thresholds',
  'total': 'Total',
};
