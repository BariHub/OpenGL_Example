# -------------------- PROJECT SETUP -------------------- #
set(CMAKE_POLICY_VERSION_MINIMUM 3.5) # to override errors of other CMake versions
cmake_minimum_required(VERSION 3.20) # set minimum version, 3.16 is common
project(OpenGLEngine LANGUAGES CXX) # stores the value into $(PROJECT_NAME)
set(CMAKE_CXX_STANDARD 20) # compiler uses C++20 for compilation
set(CMAKE_CXX_STANDARD_REQUIRED ON) # Make the standard strict and portable
set(CMAKE_CXX_EXTENSIONS OFF) # Make the standard strict and portable

include(FetchContent)
# Fetch or find dependencies (can be in cmake/FetchDeps.cmake)
#include(cmake/FetchDeps.cmake) #improvement, makes it modular

# ------------------ DEBUG: Generator & Paths ------------------ #
message(STATUS "CMake generator: ${CMAKE_GENERATOR}")
message(STATUS "CMake source dir: ${CMAKE_CURRENT_SOURCE_DIR}")
message(STATUS "CMake binary dir: ${CMAKE_CURRENT_BINARY_DIR}")

# ------------------ CREATE EXECUTABLE ------------------ #
set(APP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/app/src") # create a variable
set(SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/engine/src") # create a variable
set(INC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/engine/include") # create a variable
set(THIRDPARTY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party") # create a variable

#file(GLOB MY_SOURCES "${SRC_DIR}/*.cpp") # take all .cpp files and put it into a list
#file(GLOB MY_HEADERS "${INC_DIR}/*.h") # take all .h files and put it into a list

add_executable(${PROJECT_NAME} ${APP_DIR}/source.cpp) # turn into an object file and link into an executable
message(STATUS "Created target: ${PROJECT_NAME}")

#target_include_directories(${PROJECT_NAME} PRIVATE ${INC_DIR}) # IDE can see custom .h files
#target_sources(${PROJECT_NAME} PRIVATE ${MY_HEADERS}) # to have it appear in IDE project viewer tree

# Make this the VS startup project when generating a .sln (only affects VS generator)
if (CMAKE_GENERATOR MATCHES "Visual Studio")
  #set_property(GLOBAL PROPERTY VS_STARTUP_PROJECT ${PROJECT_NAME}) # this does not work
  message(STATUS "Set VS_STARTUP_PROJECT = ${PROJECT_NAME}")
endif()

# --------------------- FIND OpenGL --------------------- #
find_package(OpenGL REQUIRED)
target_link_libraries(${PROJECT_NAME} PRIVATE OpenGL::GL)
message(STATUS "Linked OpenGL:GL")

# --------------------- IMPORT GLEW (via FetchContent) --------------------- #
# Download GLEW from GitHub, right now is static but recommend shared
if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/glew/include/GL/glew.h")
  message(STATUS "Found GLEW header: ${CMAKE_CURRENT_SOURCE_DIR}/third_party/glew/include/GL/glew.h")
else()
  message(WARNING "GLEW header NOT found at ${CMAKE_CURRENT_SOURCE_DIR}/third_party/glew/include/GL/glew.h - check that you extracted the release zip")
endif()

# Save old BUILD_SHARED_LIBS value (so we don't clobber global behaviour), force a static build
if (DEFINED BUILD_SHARED_LIBS)
  set(_OLD_BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS}) # store old value of shared libs
  set(_OLD_BUILD_SHARED_LIBS_DEFINED TRUE) # store bool if we changed value
else()
  set(_OLD_BUILD_SHARED_LIBS_DEFINED FALSE)
endif()

# Force static GLEW (set to ON for shared). Change as needed.
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Force static GLEW" FORCE)
message(STATUS "Temporarily set BUILD_SHARED_LIBS = ${BUILD_SHARED_LIBS} for building GLEW")

# add_subdirectory will process the CMake of the GLEW repo and create the library targets
# Tell CMake to process GLEW’s own CMakeLists.txt
# GLEW’s CMake files live under the 'build/cmake' subfolder.
add_subdirectory(
                 ${CMAKE_CURRENT_SOURCE_DIR}/third_party/glew/build/cmake 
                 ${CMAKE_CURRENT_BINARY_DIR}/third_party/glew-build
                 EXCLUDE_FROM_ALL)
message(STATUS "Processed CMake found in GLEW")

message(STATUS "Checking available GLEW targets...")
if (TARGET GLEW::GLEW)
  message(STATUS "Linking to target: GLEW::GLEW")
  target_link_libraries(${PROJECT_NAME} PRIVATE GLEW::GLEW)
  set(_glew_target "GLEW::GLEW")
  message(STATUS "Linked GLEW::GLEW target")
elseif (TARGET GLEW::glew_s)
  message(STATUS "Linking to target: GLEW::glew_s (static)")
  target_link_libraries(${PROJECT_NAME} PRIVATE GLEW::glew_s)
  target_compile_definitions(${PROJECT_NAME} PRIVATE GLEW_STATIC)
  set(_glew_target "glew_s")
  message(STATUS "Linked GLEW_STATIC target")
elseif (TARGET glew_s)
  message(STATUS "Linking to target: glew_s (static)")
  target_link_libraries(${PROJECT_NAME} PRIVATE glew_s)
  target_compile_definitions(${PROJECT_NAME} PRIVATE GLEW_STATIC)
  set(_glew_target "glew_s")
  message(STATUS "Linked GLEW_STATIC target")
elseif (TARGET glew)
  message(STATUS "Linking to target: glew (shared)")
  target_link_libraries(${PROJECT_NAME} PRIVATE glew)
  set(_glew_target "glew")
  message(STATUS "Linked glew target")
else()
  message(WARNING "No GLEW target found (GLEW::GLEW / glew_s / glew). Falling back to adding include dir only.")
  set(_glew_target "")
endif()

target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/third_party/glew/include) # this ensures the GL/glew.h gets properly included in the project

# Restore previous BUILD_SHARED_LIBS (important)
if (_OLD_BUILD_SHARED_LIBS_DEFINED)
  set(BUILD_SHARED_LIBS ${_OLD_BUILD_SHARED_LIBS} CACHE BOOL "" FORCE) # set it back to previous/original value before we changed it
  message(STATUS "Restored BUILD_SHARED_LIBS to ${BUILD_SHARED_LIBS}")
else()
  unset(BUILD_SHARED_LIBS CACHE)
  message(STATUS "Unset BUILD_SHARED_LIBS (restored to undefined)")
endif()

# --------------------- IMPORT GLFW (via FetchContent) --------------------- #
FetchContent_Declare(
    glfw
    GIT_REPOSITORY https://github.com/glfw/glfw.git
    GIT_TAG        3.4
)
FetchContent_MakeAvailable(glfw)
# GLM provides the imported target glm::glm (header-only)
#add_library(glm_local INTERFACE) # declare an interface
#target_link_directories(glm_local INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/third_party/glm) # where to find the headers
#add_library(glm::local ALIAS glm_local) # create an alias to use glm::glm
add_library(glfw::glfw ALIAS glfw)
target_link_libraries(${PROJECT_NAME} PRIVATE glfw::glfw)
message(STATUS "End of glfw target")

# --------------------- IMPORT GLM (via FetchContent) --------------------- #
FetchContent_Declare(
    glm
    GIT_REPOSITORY https://github.com/g-truc/glm.git
    GIT_TAG        1.0.1
)
FetchContent_MakeAvailable(glm)
# GLM provides the imported target glm::glm (header-only)
#add_library(glm_local INTERFACE) # declare an interface
#target_link_directories(glm_local INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/third_party/glm) # where to find the headers
#add_library(glm::local ALIAS glm_local) # create an alias to use glm::glm
target_link_libraries(${PROJECT_NAME} PRIVATE glm::glm) # link it to executable
message(STATUS "End of glm::glm")

# --------------------- IMPORT IMGUI (via FetchContent) --------------------- #
FetchContent_Declare(
    imgui
    GIT_REPOSITORY https://github.com/ocornut/imgui.git
    GIT_TAG        v1.92.4
)
FetchContent_MakeAvailable(imgui) # might not need binary_dir

set(IMGUI_DIR ${imgui_SOURCE_DIR})

set(IMGUI_CORE_SRCS
  ${IMGUI_DIR}/imgui.cpp
  ${IMGUI_DIR}/imgui_draw.cpp
  ${IMGUI_DIR}/imgui_tables.cpp
  ${IMGUI_DIR}/imgui_widgets.cpp
  ${IMGUI_DIR}/imgui_demo.cpp
)

if (TARGET imgui)
  message(STATUS "Using upstream provided 'imgui' target")
else()
  message(STATUS "Creating imgui STATIC target from sources")
  add_library(imgui STATIC ${IMGUI_CORE_SRCS})
  target_include_directories(imgui PUBLIC ${IMGUI_DIR})
  # optional: avoid bringing in deprecated functions
  target_compile_definitions(imgui PUBLIC IMGUI_DISABLE_OBSOLETE_FUNCTIONS)
endif()

# --------------------- imgui backends (GLFW + OpenGL3) --------------------- #
set(IMGUI_BACKENDS
  ${IMGUI_DIR}/backends/imgui_impl_glfw.cpp
  ${IMGUI_DIR}/backends/imgui_impl_opengl3.cpp
)

# Make backend headers visible
# (add the backends dir so #include "backends/imgui_impl_*" or "imgui_impl_opengl3.h" works)
target_include_directories(imgui PUBLIC ${IMGUI_DIR} ${IMGUI_DIR}/backends)

# Add the backend sources to the imgui target (if imgui target already exists)
target_sources(imgui PRIVATE ${IMGUI_BACKENDS})

# Tell ImGui which OpenGL loader you use. Use one of:
#  IMGUI_IMPL_OPENGL_LOADER_GLEW   -> if you use GLEW
#  IMGUI_IMPL_OPENGL_LOADER_GLAD   -> if you use glad
#  IMGUI_IMPL_OPENGL_LOADER_GL3W   -> if you use gl3w
# (set the one that matches your project)
target_compile_definitions(imgui PRIVATE IMGUI_IMPL_OPENGL_LOADER_GLEW)

# _glew_target was set earlier when processing GLEW
if (_glew_target)
  target_link_libraries(imgui PUBLIC ${_glew_target})
endif()
target_link_libraries(imgui PUBLIC glfw::glfw OpenGL::GL)

add_library(imgui::imgui ALIAS imgui) # was initially inside previous if statement
target_link_libraries(${PROJECT_NAME} PRIVATE imgui::imgui)
message(STATUS "End of imgui")

# --------------------- STB_IMAGE (Included in Github Repo) --------------------- #
add_library(stb_image STATIC ${THIRDPARTY_DIR}/stb/stb_image.cpp) # or OBJECT if you prefer
target_include_directories(stb_image PUBLIC ${THIRDPARTY_DIR})
# If you used add_library(... STATIC) you will link it like a normal lib:
target_link_libraries(${PROJECT_NAME} PRIVATE stb_image)
message(STATUS "End of stb_image")
