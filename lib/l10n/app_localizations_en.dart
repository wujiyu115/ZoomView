// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ZoomView';

  @override
  String get settings => 'Settings';

  @override
  String get browsing => 'Browsing';

  @override
  String get desktopMode => 'Desktop Mode';

  @override
  String get desktopModeSubtitle => 'Load websites in desktop layout';

  @override
  String get searchEngine => 'Search Engine';

  @override
  String get homePage => 'Home Page';

  @override
  String get homePageUrl => 'Home Page URL';

  @override
  String get viewportWidth => 'Viewport Width';

  @override
  String viewportWidthValue(int width) {
    return '${width}px';
  }

  @override
  String get zoom => 'Zoom';

  @override
  String get defaultZoom => 'Default Zoom';

  @override
  String zoomPercent(int percent) {
    return '$percent%';
  }

  @override
  String get privacy => 'Privacy';

  @override
  String get clearCookies => 'Clear Cookies';

  @override
  String get cookiesCleared => 'Cookies cleared';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get about => 'About';

  @override
  String get zoomViewBrowser => 'ZoomView Browser';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String get urlHint => 'https://...';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get searchBookmarks => 'Search bookmarks...';

  @override
  String get newFolder => 'New Folder';

  @override
  String get folderName => 'Folder name';

  @override
  String get moveToFolder => 'Move to Folder';

  @override
  String get rootNoFolder => 'Root (no folder)';

  @override
  String get noFoldersAvailable => 'No folders available';

  @override
  String get noBookmarksYet => 'No bookmarks yet';

  @override
  String get deleteFolder => 'Delete Folder';

  @override
  String get history => 'History';

  @override
  String get searchHistory => 'Search history...';

  @override
  String get noHistoryEntries => 'No history entries';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get earlier => 'Earlier';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get clearHistoryConfirm =>
      'Are you sure you want to clear all history?';

  @override
  String get clear => 'Clear';

  @override
  String get downloads => 'Downloads';

  @override
  String get noDownloads => 'No downloads';

  @override
  String get pending => 'Pending';

  @override
  String get paused => 'Paused';

  @override
  String get completed => 'Completed';

  @override
  String get failed => 'Failed';

  @override
  String get share => 'Share';

  @override
  String get findInPage => 'Find in Page';

  @override
  String get findInPageHint => 'Find in page...';

  @override
  String get switchToMobileMode => 'Switch to Mobile Mode';

  @override
  String get switchToDesktopMode => 'Switch to Desktop Mode';

  @override
  String get addBookmark => 'Add Bookmark';

  @override
  String get bookmarkAdded => 'Bookmark added';

  @override
  String tabsCount(int count) {
    return 'Tabs ($count)';
  }

  @override
  String get newTab => 'New Tab';

  @override
  String get back => 'Back';
}
