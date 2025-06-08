#include "include/firebase_database/firebase_database_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace firebase_database {

// static
void FirebaseDatabasePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "plugins.flutter.io/firebase_database",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FirebaseDatabasePlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FirebaseDatabasePlugin::FirebaseDatabasePlugin() {}

FirebaseDatabasePlugin::~FirebaseDatabasePlugin() {}

void FirebaseDatabasePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // Implementation of the database methods
  if (method_call.method_name().compare("DatabaseReference#set") == 0) {
    // For now, just return success without actual implementation
    result->Success(flutter::EncodableValue(true));
  } else if (method_call.method_name().compare("DatabaseReference#update") == 0) {
    // For now, just return success without actual implementation
    result->Success(flutter::EncodableValue(true));
  } else if (method_call.method_name().compare("DatabaseReference#setPriority") == 0) {
    // For now, just return success without actual implementation
    result->Success(flutter::EncodableValue(true));
  } else if (method_call.method_name().compare("DatabaseReference#remove") == 0) {
    // For now, just return success without actual implementation
    result->Success(flutter::EncodableValue(true));
  } else if (method_call.method_name().compare("Query#get") == 0) {
    // Return an empty result for get operations
    flutter::EncodableMap map;
    result->Success(flutter::EncodableValue(map));
  } else if (method_call.method_name().compare("FirebaseDatabase#goOnline") == 0 ||
             method_call.method_name().compare("FirebaseDatabase#goOffline") == 0 ||
             method_call.method_name().compare("FirebaseDatabase#purgeOutstandingWrites") == 0 ||
             method_call.method_name().compare("FirebaseDatabase#setPersistenceEnabled") == 0 ||
             method_call.method_name().compare("FirebaseDatabase#setPersistenceCacheSizeBytes") == 0) {
    // For firebase database operations, just return success
    result->Success(flutter::EncodableValue(true));
  } else {
    result->NotImplemented();
  }
}

}  // namespace firebase_database 