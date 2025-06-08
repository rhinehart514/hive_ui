// Generated stub header for missing plugins
#ifndef FLUTTER_PLUGIN_STUBS_H_
#define FLUTTER_PLUGIN_STUBS_H_

// This header provides empty definitions for plugins that might be missing
// in the Windows platform build. It's included by the main CMakeLists.txt.

#define DECLARE_STUB_PLUGIN_CLASS(className) \
class className { \
public: \
    static void RegisterWithRegistrar() {} \
}

namespace flutter {
    // Firebase plugins
    DECLARE_STUB_PLUGIN_CLASS(FirebaseCorePlugin);
    DECLARE_STUB_PLUGIN_CLASS(FirebaseAuthPlugin);
    DECLARE_STUB_PLUGIN_CLASS(CloudFirestorePlugin);
    DECLARE_STUB_PLUGIN_CLASS(FirebaseStoragePlugin);
    
    // Other plugins
    DECLARE_STUB_PLUGIN_CLASS(ConnectivityPlusPlugin);
    DECLARE_STUB_PLUGIN_CLASS(EmojiPickerFlutterPlugin);
    DECLARE_STUB_PLUGIN_CLASS(FileSelectorPlugin);
    DECLARE_STUB_PLUGIN_CLASS(FlutterSecureStorageWindowsPlugin);
    DECLARE_STUB_PLUGIN_CLASS(PermissionHandlerWindowsPlugin);
    DECLARE_STUB_PLUGIN_CLASS(SharePlusWindowsPlugin);
    DECLARE_STUB_PLUGIN_CLASS(UrlLauncherWindowsPlugin);
    DECLARE_STUB_PLUGIN_CLASS(PackageInfoPlusWindowsPlugin);
    DECLARE_STUB_PLUGIN_CLASS(PathProviderWindowsPlugin);
}

#undef DECLARE_STUB_PLUGIN_CLASS

#endif  // FLUTTER_PLUGIN_STUBS_H_