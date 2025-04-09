// Firebase stub implementation for Windows
#pragma once

#ifdef _WIN32
#define FIREBASE_STUB_IMPLEMENTATION

#include <string>
#include <map>
#include <vector>

namespace firebase {
    class App {
    public:
        static App* Create() { return new App(); }
        static void RegisterLibrary(const char* name, const char* version = nullptr, void* context = nullptr) {}
    };

    namespace auth {
        class Auth {
        public:
            static Auth* GetAuth(App* app) { return new Auth(); }
        };
    }

    namespace firestore {
        class Firestore {
        public:
            static Firestore* GetInstance(App* app) { return new Firestore(); }
        };
    }

    namespace storage {
        class Storage {
        public:
            static Storage* GetInstance(App* app) { return new Storage(); }
        };
    }
}

#endif // _WIN32