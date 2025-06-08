#ifndef FLUTTER_PLUGIN_FIREBASE_DATABASE_PLUGIN_H_
#define FLUTTER_PLUGIN_FIREBASE_DATABASE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace firebase_database {

class FirebaseDatabasePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FirebaseDatabasePlugin();

  virtual ~FirebaseDatabasePlugin();

  // Disallow copy and assign.
  FirebaseDatabasePlugin(const FirebaseDatabasePlugin&) = delete;
  FirebaseDatabasePlugin& operator=(const FirebaseDatabasePlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace firebase_database

#endif  // FLUTTER_PLUGIN_FIREBASE_DATABASE_PLUGIN_H_ 