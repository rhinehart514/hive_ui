# CMake module to disable problematic compiler errors in Firebase on Windows
# Include this in your CMakeLists.txt to suppress variant compatibility errors

# Configure C++ standard for Firebase compatibility
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Disable deprecated std conversions to fix variant compatibility issues
add_compile_definitions(_HAS_DEPRECATED_STDCONV=0)
add_compile_definitions(_SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING)
add_compile_definitions(WINDOWS_DESKTOP=1)

# Disable specific warnings that occur with Firebase
add_compile_options(/wd4996) # Disable deprecated function warnings
add_compile_options(/wd4267) # Disable conversion from size_t warnings
add_compile_options(/wd4244) # Disable conversion from double to float warnings
add_compile_options(/wd2220) # Disable unresolved external symbol warnings
add_compile_options(/wd4828) # Disable file encoding warnings
add_compile_options(/wd4068) # Disable unknown pragma warnings

# Force the use of /MD and /MDd runtime libraries (required by Firebase)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

# Silence warnings about Google APIs
add_compile_definitions(FIREBASE_NAMESPACE=firebase)

message(STATUS "Firebase Windows compatibility settings applied") 