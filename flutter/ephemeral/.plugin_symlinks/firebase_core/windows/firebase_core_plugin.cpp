// Copyright 2023, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "firebase_core_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include "messages.g.h"

// Include Firebase headers conditionally
#ifdef FIREBASE_STUB
// Stub definitions for Firebase when SDK is not available
namespace firebase {
class App {
 public:
  static App* Create(void* options, const char* name) { return nullptr; }
  static App* GetInstance(const char* name) { return nullptr; }
  static std::vector<App*> GetApps() { return std::vector<App*>(); }
  static void RegisterLibrary(const char* library, const char* version, void* ctx) {}
  const char* name() const { return "stub_app"; }
  struct AppOptions {
    const char* api_key() const { return ""; }
    const char* app_id() const { return ""; }
    const char* database_url() const { return ""; }
    const char* messaging_sender_id() const { return ""; }
    const char* project_id() const { return ""; }
    const char* storage_bucket() const { return ""; }
  };
  AppOptions options() const { return AppOptions(); }
};

struct AppOptions {
  void set_api_key(const char* val) {}
  void set_app_id(const char* val) {}
  void set_database_url(const char* val) {}
  void set_ga_tracking_id(const char* val) {}
  void set_messaging_sender_id(const char* val) {}
  void set_project_id(const char* val) {}
  void set_storage_bucket(const char* val) {}
};
}  // namespace firebase
#else
#include "firebase/app.h"
#endif

#include <map>
#include <memory>
#include <sstream>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <future>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

#ifdef FIREBASE_STUB
// Define a stub function for getPluginVersion
namespace {
std::string getPluginVersion() { return "0.0.0"; }
}  // namespace
#else
// Include the real plugin version header
#include "firebase_core/plugin_version.h"
#endif

using ::firebase::App;

namespace firebase_core_windows {

static std::string kLibraryName = "flutter-fire-core";

// static
void FirebaseCorePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<FirebaseCorePlugin>();

  FirebaseCoreHostApi::SetUp(registrar->messenger(), plugin.get());
  FirebaseAppHostApi::SetUp(registrar->messenger(), plugin.get());

  registrar->AddPlugin(std::move(plugin));

  // Skip RegisterLibrary in stub mode
  #ifndef FIREBASE_STUB
  // Register for platform logging
  #if FIREBASE_VERSION_MAJOR >= 11
  // Firebase SDK 11.x+ only takes the library name
  App::RegisterLibrary(kLibraryName.c_str());
  #else
  // Older Firebase SDK versions take name and version
  #if FIREBASE_VERSION_MAJOR >= 11
  // Firebase SDK 11.x+ only takes the library name
  App::RegisterLibrary(kLibraryName.c_str());
#else
  // Older Firebase SDK versions take name and version
  #if FIREBASE_VERSION_MAJOR >= 11
  // Firebase SDK 11.x+ only takes the library name
  App::RegisterLibrary(kLibraryName.c_str());
#else
  // Older Firebase SDK versions take name and version
  App::RegisterLibrary(kLibraryName.c_str(), getPluginVersion().c_str(), nullptr);
#endif
#endif
  #endif
  #endif
}

FirebaseCorePlugin::FirebaseCorePlugin() {}

FirebaseCorePlugin::~FirebaseCorePlugin() = default;

#ifndef FIREBASE_STUB
// Only define these when using the real Firebase SDK

// Convert a Pigeon FirebaseOptions to a Firebase Options.
firebase::AppOptions PigeonFirebaseOptionsToAppOptions(
    const PigeonFirebaseOptions &pigeon_options) {
  firebase::AppOptions options;
  options.set_api_key(pigeon_options.api_key().c_str());
  options.set_app_id(pigeon_options.app_id().c_str());
  if (pigeon_options.database_u_r_l() != nullptr) {
    options.set_database_url(pigeon_options.database_u_r_l()->c_str());
  }
  if (pigeon_options.tracking_id() != nullptr) {
    options.set_ga_tracking_id(pigeon_options.tracking_id()->c_str());
  }
  options.set_messaging_sender_id(pigeon_options.messaging_sender_id().c_str());

  options.set_project_id(pigeon_options.project_id().c_str());

  if (pigeon_options.storage_bucket() != nullptr) {
    options.set_storage_bucket(pigeon_options.storage_bucket()->c_str());
  }
  return options;
}

// Convert a AppOptions to PigeonInitializeOption
PigeonFirebaseOptions optionsFromFIROptions(
    const firebase::AppOptions &options) {
  PigeonFirebaseOptions pigeon_options = PigeonFirebaseOptions();
  pigeon_options.set_api_key(options.api_key());
  pigeon_options.set_app_id(options.app_id());
  // AppOptions initialises as empty char so we check to stop empty string to
  // Flutter Same for storage bucket below
  const char *db_url = options.database_url();
  if (db_url != nullptr && db_url[0] != '\0') {
    pigeon_options.set_database_u_r_l(db_url);
  }
  pigeon_options.set_tracking_id(nullptr);
  pigeon_options.set_messaging_sender_id(options.messaging_sender_id());
  pigeon_options.set_project_id(options.project_id());

  const char *storage_bucket = options.storage_bucket();
  if (storage_bucket != nullptr && storage_bucket[0] != '\0') {
    pigeon_options.set_storage_bucket(storage_bucket);
  }
  return pigeon_options;
}

// Convert a firebase::App to PigeonInitializeResponse
PigeonInitializeResponse AppToPigeonInitializeResponse(const App &app) {
  PigeonInitializeResponse response = PigeonInitializeResponse();
  response.set_name(app.name());
  response.set_options(optionsFromFIROptions(app.options()));
  return response;
}
#endif

void FirebaseCorePlugin::InitializeApp(
    const std::string &app_name,
    const PigeonFirebaseOptions &initialize_app_request,
    std::function<void(ErrorOr<PigeonInitializeResponse> reply)> result) {
  #ifdef FIREBASE_STUB
  // Return stub app data when Firebase SDK is not available
  PigeonInitializeResponse response;
  response.set_name("[DEFAULT]");
  response.set_options(PigeonFirebaseOptions());
  
  // Create empty plugin constants map
  flutter::EncodableMap plugin_constants;
  response.set_plugin_constants(plugin_constants);
  
  result(response);
  #else
  // Use real Firebase implementation
  result(FlutterError("unimplemented", "Not implemented on Windows", nullptr));
  #endif
}

void FirebaseCorePlugin::InitializeCore(
    std::function<void(ErrorOr<flutter::EncodableList> reply)> result) {
  #ifdef FIREBASE_STUB
  // Return empty app list when using stub implementation
  flutter::EncodableList apps;
  
  // Create a default app entry
  flutter::EncodableMap app_data;
  app_data[flutter::EncodableValue("name")] = flutter::EncodableValue("[DEFAULT]");
  app_data[flutter::EncodableValue("options")] = flutter::EncodableMap();
  app_data[flutter::EncodableValue("pluginConstants")] = flutter::EncodableMap();
  
  apps.push_back(flutter::EncodableValue(app_data));
  result(apps);
  #else
  // Use real Firebase implementation
  result(FlutterError("unimplemented", "Not implemented on Windows", nullptr));
  #endif
}

void FirebaseCorePlugin::OptionsFromResource(
    std::function<void(ErrorOr<PigeonFirebaseOptions> reply)> result) {
  #ifdef FIREBASE_STUB
  // Return empty options
  PigeonFirebaseOptions options;
  result(options);
  #else
  // Use real Firebase implementation
  result(FlutterError("unimplemented", "Not implemented on Windows", nullptr));
  #endif
}

void FirebaseCorePlugin::SetAutomaticDataCollectionEnabled(
    const std::string &app_name, bool enabled,
    std::function<void(std::optional<FlutterError> reply)> result) {
  #ifdef FIREBASE_STUB
  // Just return success in stub mode
  result(std::nullopt);
  #else
  result(FlutterError("unimplemented", "Not implemented on Windows", nullptr));
  #endif
}

void FirebaseCorePlugin::SetAutomaticResourceManagementEnabled(
    const std::string &app_name, bool enabled,
    std::function<void(std::optional<FlutterError> reply)> result) {
  #ifdef FIREBASE_STUB
  // Just return success in stub mode
  result(std::nullopt);
  #else
  result(FlutterError("unimplemented", "Not implemented on Windows", nullptr));
  #endif
}

void FirebaseCorePlugin::Delete(
    const std::string &app_name,
    std::function<void(std::optional<FlutterError> reply)> result) {
  #ifdef FIREBASE_STUB
  // Just return success in stub mode
  result(std::nullopt);
  #else
  result(FlutterError("unimplemented", "Not implemented on Windows", nullptr));
  #endif
}

}  // namespace firebase_core_windows
