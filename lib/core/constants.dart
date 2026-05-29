class AppConstants {
  AppConstants._();

  static const String desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

  static const String mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36';

  static const double minZoom = 0.5;
  static const double maxZoom = 3.0;
  static const double defaultZoom = 1.0;
  static const double zoomStep = 0.1;
  static const int defaultViewportWidth = 1920;

  static const String defaultHomeUrl = 'https://www.google.com';

  static const Map<String, String> searchEngines = {
    'Google': 'https://www.google.com/search?q=%s',
    'Bing': 'https://www.bing.com/search?q=%s',
    'DuckDuckGo': 'https://duckduckgo.com/?q=%s',
  };

  static const int maxConcurrentDownloads = 3;
}
