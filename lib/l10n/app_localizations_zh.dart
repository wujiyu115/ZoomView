// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'ZoomView';

  @override
  String get settings => '设置';

  @override
  String get browsing => '浏览';

  @override
  String get desktopMode => '桌面模式';

  @override
  String get desktopModeSubtitle => '以桌面版布局加载网页';

  @override
  String get searchEngine => '搜索引擎';

  @override
  String get homePage => '主页';

  @override
  String get homePageUrl => '主页网址';

  @override
  String get viewportWidth => '视口宽度';

  @override
  String viewportWidthValue(int width) {
    return '${width}px';
  }

  @override
  String get zoom => '缩放';

  @override
  String get defaultZoom => '默认缩放';

  @override
  String zoomPercent(int percent) {
    return '$percent%';
  }

  @override
  String get privacy => '隐私';

  @override
  String get clearCookies => '清除 Cookies';

  @override
  String get cookiesCleared => 'Cookies 已清除';

  @override
  String get clearCache => '清除缓存';

  @override
  String get cacheCleared => '缓存已清除';

  @override
  String get appearance => '外观';

  @override
  String get darkMode => '深色模式';

  @override
  String get about => '关于';

  @override
  String get zoomViewBrowser => 'ZoomView 浏览器';

  @override
  String version(String version) {
    return '版本 $version';
  }

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get create => '创建';

  @override
  String get delete => '删除';

  @override
  String get urlHint => 'https://...';

  @override
  String get bookmarks => '书签';

  @override
  String get searchBookmarks => '搜索书签...';

  @override
  String get newFolder => '新建文件夹';

  @override
  String get folderName => '文件夹名称';

  @override
  String get moveToFolder => '移动到文件夹';

  @override
  String get rootNoFolder => '根目录（无文件夹）';

  @override
  String get noFoldersAvailable => '暂无文件夹';

  @override
  String get noBookmarksYet => '暂无书签';

  @override
  String get deleteFolder => '删除文件夹';

  @override
  String get history => '历史记录';

  @override
  String get searchHistory => '搜索历史记录...';

  @override
  String get noHistoryEntries => '暂无历史记录';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get earlier => '更早';

  @override
  String get clearHistory => '清除历史记录';

  @override
  String get clearHistoryConfirm => '确定要清除所有历史记录吗？';

  @override
  String get clear => '清除';

  @override
  String get downloads => '下载';

  @override
  String get noDownloads => '暂无下载';

  @override
  String get pending => '等待中';

  @override
  String get paused => '已暂停';

  @override
  String get completed => '已完成';

  @override
  String get failed => '失败';

  @override
  String get share => '分享';

  @override
  String get findInPage => '页面内查找';

  @override
  String get findInPageHint => '页面内查找...';

  @override
  String get switchToMobileMode => '切换到移动模式';

  @override
  String get switchToDesktopMode => '切换到桌面模式';

  @override
  String get addBookmark => '添加书签';

  @override
  String get bookmarkAdded => '书签已添加';

  @override
  String tabsCount(int count) {
    return '标签页 ($count)';
  }

  @override
  String get newTab => '新标签页';

  @override
  String get back => '返回';

  @override
  String get downloadConfirmTitle => '下载文件';

  @override
  String get download => '下载';

  @override
  String get downloading => '下载中...';

  @override
  String get searchOrEnterUrl => '搜索或输入网址';

  @override
  String get quickAccess => '快速访问';

  @override
  String get recentVisits => '最近访问';

  @override
  String get done => '完成';

  @override
  String get edit => '编辑';

  @override
  String get earlierThisWeek => '本周早些时候';
}
