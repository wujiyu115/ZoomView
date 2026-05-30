# ZoomView

一款基于 Flutter 的 iOS/Android 全功能浏览器，支持精细缩放控制、下载管理和桌面模式。

## 功能概述

### 浏览器核心
- **多标签页** — 创建、切换、关闭标签页，标签页网格管理器
- **缩放控制** — 底部滑块 + 按钮精细调节（0.5x–3.0x），缩放级别跨页面保持
- **桌面/移动模式** — 切换 User-Agent，桌面模式可自定义视口宽度（1280/1920/2560）
- **起始页** — 快速访问网站 + 最近访问记录
- **页面内查找** — 底部搜索栏，上下导航匹配项
- **全屏模式** — 可拖拽浮动按钮切换，隐藏工具栏和缩放条

### 下载管理
- **自动下载检测** — MIME 类型白名单、URL 扩展名、Content-Disposition 头
- **进度追踪** — 实时进度条，后台下载支持
- **Cookie 透传** — 自动从 WebView 获取 cookies 传递给下载器，支持需要登录的下载
- **文件分享** — 下载完成后通过系统分享面板导出

### 书签与历史
- **书签管理** — 文件夹分组、搜索、排序、移动
- **历史记录** — 按日期分组（今天/昨天/更早），搜索，一键清除

### 设置
- **深色/浅色模式** — 跟随系统或手动切换
- **搜索引擎** — Google / Bing / DuckDuckGo
- **隐私** — 清除 Cookies、清除缓存
- **开发者工具** — 分级日志记录（debug/info/warning/error），应用内日志查看器，日志导出

### 反检测
- 伪装为 Chrome for iOS / macOS Safari，匹配 WKWebView 平台指纹
- 完整的 `chrome.app/runtime/csi/loadTimes` 对象
- WebGL vendor/renderer 一致性（Apple Inc. / Apple GPU）
- 清理 WebView 自动化标记

## 项目结构

```
lib/
├── core/
│   ├── app_colors.dart          # 颜色系统（深色/浅色）
│   ├── constants.dart           # UA、缩放范围、搜索引擎
│   ├── extensions.dart          # BuildContext 扩展
│   ├── theme.dart               # Material 主题配置
│   ├── database/                # SQLite 数据库
│   ├── logger/                  # AppLogger 分级日志
│   └── widgets/                 # 共享 UI 组件
├── features/
│   ├── browser/                 # 浏览器核心
│   │   ├── models/              # TabModel
│   │   ├── providers/           # BrowserNotifier (Riverpod)
│   │   └── widgets/             # 工具栏、URL栏、起始页、WebView容器
│   ├── bookmarks/               # 书签（文件夹 + 条目）
│   ├── downloads/               # 下载管理
│   ├── history/                 # 浏览历史
│   └── settings/                # 设置
├── l10n/                        # 国际化（中文/英文）
├── app.dart                     # MaterialApp 入口
└── main.dart                    # 启动 + flutter_downloader 初始化
```

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.11+ / Dart |
| 状态管理 | Riverpod (NotifierProvider) |
| WebView | flutter_inappwebview |
| 下载 | flutter_downloader + NSURLSession |
| 数据库 | sqflite (SQLite) |
| 国际化 | Flutter intl (ARB) |

## 开发指南

### 环境要求

- Flutter SDK ≥ 3.11.5
- Xcode 16+（iOS 开发）
- CocoaPods

### 构建运行

```bash
# 安装依赖
flutter pub get

# iOS 模拟器
flutter run

# iOS 真机（需要 Apple Developer 证书）
flutter run --release

# 生成国际化文件（修改 .arb 后）
flutter gen-l10n

# 生成应用图标
dart run flutter_launcher_icons
```

### 添加新设置项

1. `lib/features/settings/models/settings_model.dart` — 添加字段 + `copyWith` + `fromMap`
2. `lib/features/settings/providers/settings_provider.dart` — 添加 setter 方法
3. `lib/features/settings/widgets/settings_screen.dart` — 添加 `_SettingsRow`

### 添加新翻译

1. 在 `lib/l10n/app_en.arb` 和 `app_zh.arb` 添加 key-value
2. 运行 `flutter gen-l10n`
3. 通过 `AppLocalizations.of(context)!.yourKey` 使用

### 日志调试

```dart
import 'package:zoomview/core/logger/app_logger.dart';

AppLogger.instance.d('Tag', 'debug message');
AppLogger.instance.i('Tag', 'info message');
AppLogger.instance.w('Tag', 'warning message');
AppLogger.instance.e('Tag', 'error message');
```

设置 → 开发者 → 开启日志 → 查看/导出日志。无论开关状态，日志始终输出到控制台。

## License

MIT
