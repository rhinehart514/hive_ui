#ifndef FIREBASE_WRAPPER_H_
#define FIREBASE_WRAPPER_H_

/**
 * This file provides stub declarations for Firebase C++ SDK functions that
 * are required for compilation but not actually used on Windows.
 * These declarations help the application compile without errors,
 * while the actual implementation is either mocked or bypassed at runtime.
 */

#ifdef WINDOWS_DESKTOP

#include <functional>
#include <memory>
#include <string>
#include <map>
#include <vector>

namespace firebase {

// Forward declarations for Firebase classes
class App;
class Auth;

namespace auth {
    
struct User {
    std::string uid;
    std::string display_name;
    std::string email;
    std::string photo_url;
    
    bool is_anonymous() const { return false; }
    bool is_email_verified() const { return false; }
};

// Stub classes that will be replaced with mocks
class Auth {
public:
    static Auth* GetAuth(App* app) { return nullptr; }
    User* current_user() { return nullptr; }
};

} // namespace auth

namespace firestore {

class DocumentReference;
class CollectionReference;
class Firestore;
class Query;

// Stub classes for Firestore
class Firestore {
public:
    static Firestore* GetInstance(App* app) { return nullptr; }
    CollectionReference* Collection(const std::string& name) { return nullptr; }
};

class DocumentReference {
public:
    CollectionReference* Collection(const std::string& name) { return nullptr; }
};

class CollectionReference {
public:
    DocumentReference* Document(const std::string& name) { return nullptr; }
};

} // namespace firestore

} // namespace firebase

#endif // WINDOWS_DESKTOP

#endif // FIREBASE_WRAPPER_H_ 