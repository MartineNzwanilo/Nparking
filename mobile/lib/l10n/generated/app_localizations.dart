import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sw'),
  ];

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @leaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get leaves;

  /// No description provided for @directory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get directory;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @employeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeId;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get invalidCredentials;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by JAcMic IoT'**
  String get developedBy;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @activeTasks.
  ///
  /// In en, this message translates to:
  /// **'Active Tasks'**
  String get activeTasks;

  /// No description provided for @myActiveTasks.
  ///
  /// In en, this message translates to:
  /// **'My Active Tasks'**
  String get myActiveTasks;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @weeklyProgress.
  ///
  /// In en, this message translates to:
  /// **'Weekly Progress'**
  String get weeklyProgress;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @startWork.
  ///
  /// In en, this message translates to:
  /// **'Start Work'**
  String get startWork;

  /// No description provided for @verifyAndFinish.
  ///
  /// In en, this message translates to:
  /// **'Verify & Finish'**
  String get verifyAndFinish;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due Tomorrow'**
  String get dueTomorrow;

  /// No description provided for @leaveManagement.
  ///
  /// In en, this message translates to:
  /// **'Leave Management'**
  String get leaveManagement;

  /// No description provided for @recentRequests.
  ///
  /// In en, this message translates to:
  /// **'Recent Requests'**
  String get recentRequests;

  /// No description provided for @noRecentRequests.
  ///
  /// In en, this message translates to:
  /// **'No recent leave requests'**
  String get noRecentRequests;

  /// No description provided for @annual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annual;

  /// No description provided for @sick.
  ///
  /// In en, this message translates to:
  /// **'Sick'**
  String get sick;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'SYNCED'**
  String get synced;

  /// No description provided for @unsyncedChanges.
  ///
  /// In en, this message translates to:
  /// **'UNSYNCED CHANGES'**
  String get unsyncedChanges;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE MODE'**
  String get offlineMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @liveLocation.
  ///
  /// In en, this message translates to:
  /// **'Live Location'**
  String get liveLocation;

  /// No description provided for @trackingOn.
  ///
  /// In en, this message translates to:
  /// **'Live Location'**
  String get trackingOn;

  /// No description provided for @trackingOff.
  ///
  /// In en, this message translates to:
  /// **'Tracking Off'**
  String get trackingOff;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable Mandatory Tracking'**
  String get enableLocation;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'GPS tracking is mandatory for all employees. Please enable location services to continue.'**
  String get locationPermissionRequired;

  /// No description provided for @searchTasks.
  ///
  /// In en, this message translates to:
  /// **'Search tasks...'**
  String get searchTasks;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @noTasksFound.
  ///
  /// In en, this message translates to:
  /// **'No tasks found'**
  String get noTasksFound;

  /// No description provided for @taskDetails.
  ///
  /// In en, this message translates to:
  /// **'Task Details'**
  String get taskDetails;

  /// No description provided for @lastLocationCapture.
  ///
  /// In en, this message translates to:
  /// **'Last location capture'**
  String get lastLocationCapture;

  /// No description provided for @filterOptions.
  ///
  /// In en, this message translates to:
  /// **'Filter Options'**
  String get filterOptions;

  /// No description provided for @jobArea.
  ///
  /// In en, this message translates to:
  /// **'Job Area'**
  String get jobArea;

  /// No description provided for @taskDuration.
  ///
  /// In en, this message translates to:
  /// **'Task Duration'**
  String get taskDuration;

  /// No description provided for @startedAt.
  ///
  /// In en, this message translates to:
  /// **'Started at'**
  String get startedAt;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @targetArea.
  ///
  /// In en, this message translates to:
  /// **'Target Area'**
  String get targetArea;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @searchEmployees.
  ///
  /// In en, this message translates to:
  /// **'Search employees...'**
  String get searchEmployees;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @noEmployeesFound.
  ///
  /// In en, this message translates to:
  /// **'No employees found'**
  String get noEmployeesFound;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @workEmail.
  ///
  /// In en, this message translates to:
  /// **'Work Email'**
  String get workEmail;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @taskVerification.
  ///
  /// In en, this message translates to:
  /// **'Task Verification'**
  String get taskVerification;

  /// No description provided for @captureProof.
  ///
  /// In en, this message translates to:
  /// **'Capture Proof'**
  String get captureProof;

  /// No description provided for @captureDescription.
  ///
  /// In en, this message translates to:
  /// **'Please take a clear photo of the completed work for verification.'**
  String get captureDescription;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @confirmAndFinish.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Finish'**
  String get confirmAndFinish;

  /// No description provided for @taskHistory.
  ///
  /// In en, this message translates to:
  /// **'Task History'**
  String get taskHistory;

  /// No description provided for @completedOn.
  ///
  /// In en, this message translates to:
  /// **'Completed on'**
  String get completedOn;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks yet'**
  String get noHistory;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @applyForLeave.
  ///
  /// In en, this message translates to:
  /// **'Apply for Leave'**
  String get applyForLeave;

  /// No description provided for @leaveSelection.
  ///
  /// In en, this message translates to:
  /// **'Leave Selection'**
  String get leaveSelection;

  /// No description provided for @selectLeaveType.
  ///
  /// In en, this message translates to:
  /// **'Select Leave Type'**
  String get selectLeaveType;

  /// No description provided for @leaveType.
  ///
  /// In en, this message translates to:
  /// **'Leave Type'**
  String get leaveType;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @selectDates.
  ///
  /// In en, this message translates to:
  /// **'Select Dates'**
  String get selectDates;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @justification.
  ///
  /// In en, this message translates to:
  /// **'Justification'**
  String get justification;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @referenceRequired.
  ///
  /// In en, this message translates to:
  /// **'Reference (Required)'**
  String get referenceRequired;

  /// No description provided for @referenceHint.
  ///
  /// In en, this message translates to:
  /// **'Enter document # or reason code'**
  String get referenceHint;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplication;

  /// No description provided for @annualLeave.
  ///
  /// In en, this message translates to:
  /// **'Annual Leave'**
  String get annualLeave;

  /// No description provided for @sickLeave.
  ///
  /// In en, this message translates to:
  /// **'Sick Leave'**
  String get sickLeave;

  /// No description provided for @personalLeave.
  ///
  /// In en, this message translates to:
  /// **'Personal Leave'**
  String get personalLeave;

  /// No description provided for @maternityLeave.
  ///
  /// In en, this message translates to:
  /// **'Maternity Leave'**
  String get maternityLeave;

  /// No description provided for @paternityLeave.
  ///
  /// In en, this message translates to:
  /// **'Paternity Leave'**
  String get paternityLeave;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No leave requests found'**
  String get noRequests;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @realTimeEarnings.
  ///
  /// In en, this message translates to:
  /// **'Real-time Earnings'**
  String get realTimeEarnings;

  /// No description provided for @earnedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Earned This Month'**
  String get earnedThisMonth;

  /// No description provided for @nextPayday.
  ///
  /// In en, this message translates to:
  /// **'Next Payday'**
  String get nextPayday;

  /// No description provided for @incomeAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Income Analysis'**
  String get incomeAnalysis;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @baseSalary.
  ///
  /// In en, this message translates to:
  /// **'Base Salary'**
  String get baseSalary;

  /// No description provided for @bonuses.
  ///
  /// In en, this message translates to:
  /// **'Bonuses'**
  String get bonuses;

  /// No description provided for @deductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get deductions;

  /// No description provided for @reportPaymentDelay.
  ///
  /// In en, this message translates to:
  /// **'Report Payment Delay'**
  String get reportPaymentDelay;

  /// No description provided for @paymentSubject.
  ///
  /// In en, this message translates to:
  /// **'Payment Issue Subject'**
  String get paymentSubject;

  /// No description provided for @paymentMessage.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue'**
  String get paymentMessage;

  /// No description provided for @submitComplaint.
  ///
  /// In en, this message translates to:
  /// **'Submit Complaint'**
  String get submitComplaint;

  /// No description provided for @complaintSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Complaint submitted successfully'**
  String get complaintSubmitted;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(Object count);

  /// No description provided for @hoursCount.
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String hoursCount(Object count);

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @myGear.
  ///
  /// In en, this message translates to:
  /// **'My Gear'**
  String get myGear;

  /// No description provided for @requestItem.
  ///
  /// In en, this message translates to:
  /// **'Request Item'**
  String get requestItem;

  /// No description provided for @returnItem.
  ///
  /// In en, this message translates to:
  /// **'Return Item'**
  String get returnItem;

  /// No description provided for @transferRequest.
  ///
  /// In en, this message translates to:
  /// **'Transfer Request'**
  String get transferRequest;

  /// No description provided for @serialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial Number'**
  String get serialNumber;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned To'**
  String get assignedTo;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @itemCondition.
  ///
  /// In en, this message translates to:
  /// **'Item Condition'**
  String get itemCondition;

  /// No description provided for @assignmentHistory.
  ///
  /// In en, this message translates to:
  /// **'Assignment History'**
  String get assignmentHistory;

  /// No description provided for @ispEquipment.
  ///
  /// In en, this message translates to:
  /// **'ISP Equipment'**
  String get ispEquipment;

  /// No description provided for @cctvKit.
  ///
  /// In en, this message translates to:
  /// **'CCTV Kit'**
  String get cctvKit;

  /// No description provided for @electricalFence.
  ///
  /// In en, this message translates to:
  /// **'Electrical Fence'**
  String get electricalFence;

  /// No description provided for @generalTools.
  ///
  /// In en, this message translates to:
  /// **'General Tools'**
  String get generalTools;

  /// No description provided for @requestTransfer.
  ///
  /// In en, this message translates to:
  /// **'Request Transfer'**
  String get requestTransfer;

  /// No description provided for @requestMissingItem.
  ///
  /// In en, this message translates to:
  /// **'Request Missing Item'**
  String get requestMissingItem;

  /// No description provided for @itemNotListed.
  ///
  /// In en, this message translates to:
  /// **'Item Not Listed?'**
  String get itemNotListed;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @itemCategory.
  ///
  /// In en, this message translates to:
  /// **'Item Category'**
  String get itemCategory;

  /// No description provided for @whyNeeded.
  ///
  /// In en, this message translates to:
  /// **'Why do you need this?'**
  String get whyNeeded;

  /// No description provided for @myAssetsReport.
  ///
  /// In en, this message translates to:
  /// **'My Assets Report'**
  String get myAssetsReport;

  /// No description provided for @totalItemsHeld.
  ///
  /// In en, this message translates to:
  /// **'Total Items Held'**
  String get totalItemsHeld;

  /// No description provided for @conditionSummary.
  ///
  /// In en, this message translates to:
  /// **'Condition Summary'**
  String get conditionSummary;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @itemReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Installing new site at Kigamboni'**
  String get itemReasonHint;

  /// No description provided for @personalAsset.
  ///
  /// In en, this message translates to:
  /// **'Work Tool'**
  String get personalAsset;

  /// No description provided for @projectAsset.
  ///
  /// In en, this message translates to:
  /// **'Onsite Item'**
  String get projectAsset;

  /// No description provided for @installationSite.
  ///
  /// In en, this message translates to:
  /// **'Installation Site'**
  String get installationSite;

  /// No description provided for @forProjectUse.
  ///
  /// In en, this message translates to:
  /// **'Onsite / Installation'**
  String get forProjectUse;

  /// No description provided for @forPersonalUse.
  ///
  /// In en, this message translates to:
  /// **'Daily Work Use'**
  String get forPersonalUse;

  /// No description provided for @personalEquipment.
  ///
  /// In en, this message translates to:
  /// **'My Work Tools (Daily)'**
  String get personalEquipment;

  /// No description provided for @projectStock.
  ///
  /// In en, this message translates to:
  /// **'Onsite / Project Stock'**
  String get projectStock;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
