# Detects whether this is a top-level project
get_directory_property(HAS_PARENT PARENT_DIRECTORY)
if(HAS_PARENT)
  set(FLOAT_TETWILD_TOPLEVEL_PROJECT OFF)
else()
  set(FLOAT_TETWILD_TOPLEVEL_PROJECT ON)
endif()

# Check required CMake version
set(REQUIRED_CMAKE_VERSION "3.18.0")
if(FLOAT_TETWILD_TOPLEVEL_PROJECT)
  cmake_minimum_required(VERSION ${REQUIRED_CMAKE_VERSION})
else()
  # Don't use cmake_minimum_required here to avoid implicitly overriding parent policies
  if(${CMAKE_VERSION} VERSION_LESS ${REQUIRED_CMAKE_VERSION})
    message(FATAL_ERROR "CMake required version to build fTetWild is ${REQUIRED_CMAKE_VERSION}")
  endif()
endif()

# Include user-provided default options if available. We do that before the main
# `project()` so that we can define the C/C++ compilers from the option file.
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/fTetWildOptionsf.cmake)
  message(STATUS "Using local options file: ${CMAKE_CURRENT_SOURCE_DIR}/fTetWildOptions.cmake")
  include(${CMAKE_CURRENT_SOURCE_DIR}/fTetWildOptions.cmake)
endif()

# Enable ccache if available
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
  option(FLOAT_TETWILD_WITH_CCACHE "Enable ccache when building fTetWild" ${FLOAT_TETWILD_TOPLEVEL_PROJECT})
else()
  option(FLOAT_TETWILD_WITH_CCACHE "Enable ccache when building fTetWild" OFF)
endif()
if(FLOAT_TETWILD_WITH_CCACHE AND CCACHE_PROGRAM)
  message(STATUS "Enabling Ccache support (${CCACHE_PROGRAM})")
  set(ccacheEnv
    CCACHE_BASEDIR=${CMAKE_BINARY_DIR}
    CCACHE_SLOPPINESS=clang_index_store,include_file_ctime,include_file_mtime,locale,pch_defines,time_macros
  )
  foreach(lang IN ITEMS C CXX)
    set(CMAKE_${lang}_COMPILER_LAUNCHER
      ${CMAKE_COMMAND} -E env ${ccacheEnv} ${CCACHE_PROGRAM}
    )
  endforeach()
endif()

################################################################################
# CMake Policies
################################################################################

cmake_policy(SET CMP0054 NEW) # Only interpret if() arguments as variables or keywords when unquoted.
cmake_policy(SET CMP0076 NEW) # target_sources() command converts relative paths to absolute.
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.24")
  cmake_policy(SET CMP0135 NEW) # Set the timestamps of all extracted contents to the time of the extraction.
endif()

################################################################################

project(FloatTetwild)

# FloatTetwild options
option(FLOAT_TETWILD_ENABLE_TBB          "Enable TBB"                     ON)
option(FLOAT_TETWILD_USE_FLOAT           "Use floats instead of double"  OFF)
option(FLOAT_TETWILD_WITH_SANITIZERS     "Use sanitizers"                OFF)
option(FLOAT_TETWILD_WITH_EXACT_ENVELOPE "Use exact envelope"            OFF)

# Sanitizer options
option(SANITIZE_ADDRESS   "Sanitize Address"       OFF)
option(SANITIZE_MEMORY    "Sanitize Memory"        OFF)
option(SANITIZE_THREAD    "Sanitize Thread"        OFF)
option(SANITIZE_UNDEFINED "Sanitize Undefined"     OFF)

# Set default minimum C++ standard
if(IPC_TOOLKIT_TOPLEVEL_PROJECT)
	set(CMAKE_CXX_STANDARD 14)
	set(CMAKE_CXX_STANDARD_REQUIRED ON)
	set(CMAKE_CXX_EXTENSIONS OFF)
endif()

# Sanitizers
if(FLOAT_TETWILD_WITH_SANITIZERS)
	list(APPEND CMAKE_MODULE_PATH ${FLOAT_TETWILD_EXTERNAL}/sanitizers-cmake/cmake)
endif()

### Configuration
set(FLOAT_TETWILD_SOURCE_DIR "${PROJECT_SOURCE_DIR}/src/floattetwild")
set(FLOAT_TETWILD_INCLUDE_DIR "${PROJECT_SOURCE_DIR}/src")

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/ftetwild/")
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/recipes/")
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/find/")

# General CMake utils
include(ftetwild_cpm_cache)
include(ftetwild_use_colors)
include(ftetwild_add_application)

# Sort projects inside the solution
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# Generate position independent code by default
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

################################################################################
# FloatTetwild Library
################################################################################

# Add an empty library and fill in the list of sources in `src/ftetwild/CMakeLists.txt`.
add_library(${PROJECT_NAME})
add_library(ftetwild::ftetwild ALIAS ${PROJECT_NAME})

# Add Sources
add_subdirectory("${FLOAT_TETWILD_SOURCE_DIR}")

# Public include directory for FloatTetwild
target_include_directories(${PROJECT_NAME} PUBLIC "${FLOAT_TETWILD_INCLUDE_DIR}")

################################################################################
# Optional Definitions
################################################################################

if(FLOAT_TETWILD_USE_FLOAT)
	target_compile_definitions(${PROJECT_NAME} PUBLIC FLOAT_TETWILD_USE_FLOAT)
endif()

################################################################################
# Dependencies
################################################################################

# libigl
include(libigl)
target_link_libraries(${PROJECT_NAME} PUBLIC igl::core igl::predicates)

# geogram
include(geogram)
target_link_libraries(${PROJECT_NAME} PUBLIC geogram)

# spdlog
include(spdlog)
target_link_libraries(${PROJECT_NAME} PUBLIC spdlog::spdlog)

# C++11 Threads
find_package(Threads REQUIRED)
target_link_libraries(${PROJECT_NAME} PUBLIC Threads::Threads)

# fast_winding_number
# NOTE: Disabled

# json
include(json)
target_link_libraries(${PROJECT_NAME} PUBLIC nlohmann_json::nlohmann_json)

# GMP
find_package(GMP)
target_link_libraries(${PROJECT_NAME} PUBLIC gmp::gmp)

# MPFR
# NOTE: Disabled

# TBB
if(FLOAT_TETWILD_ENABLE_TBB)
	include(onetbb)
	target_link_libraries(${PROJECT_NAME} PUBLIC TBB::tbb)
endif()

# FastEnvelope
if(FLOAT_TETWILD_WITH_EXACT_ENVELOPE)
	include(fast_envelope)
	target_link_libraries(${PROJECT_NAME} PUBLIC fast_envelope::fast_envelope)
	target_compile_definitions(${PROJECT_NAME} PUBLIC NEW_ENVELOPE)
endif()

# Sanitizers
if(FLOAT_TETWILD_WITH_SANITIZERS)
	include(sanitizer)
	add_sanitizers(${PROJECT_NAME})
endif()

if(FLOAT_TETWILD_TOPLEVEL_PROJECT AND TARGET igl::tetgen)
	target_link_libraries(${PROJECT_NAME} PUBLIC igl::tetgen)
	target_compile_definitions(${PROJECT_NAME} PUBLIC -DLIBIGL_WITH_TETGEN)
endif()

# Extra warnings (link last for highest priority)
include(ftetwild_warnings)
target_link_libraries(${PROJECT_NAME} PRIVATE ftetwild::warnings)

################################################################################
# Compiler options
################################################################################

# Use C++11
target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_11)

################################################################################
# FloatTetwild binary
################################################################################

# Main executable
if(FLOAT_TETWILD_TOPLEVEL_PROJECT)
	add_executable(${PROJECT_NAME}_bin src/main.cpp)
	target_compile_features(${PROJECT_NAME}_bin PUBLIC ${CXX14_FEATURES})

	target_link_libraries(${PROJECT_NAME}_bin PUBLIC ftetwild::ftetwild)

	include(cli11)
	target_link_libraries(${PROJECT_NAME}_bin PUBLIC CLI11::CLI11)

	include(ftetwild_warnings)
	target_link_libraries(${PROJECT_NAME}_bin PRIVATE ftetwild::warnings)

	if(FLOAT_TETWILD_WITH_SANITIZERS)
		include(sanitizer)
		add_sanitizers(${PROJECT_NAME}_bin)
	endif()

	if(NOT (${CMAKE_VERSION} VERSION_LESS "3.6.0"))
		set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${PROJECT_NAME}_bin)
	endif()
endif()

################################################################################
# Tests
################################################################################

# set(MESH_PATH "${CMAKE_CURRENT_SOURCE_DIR}/tests/")
# target_compile_definitions(${PROJECT_NAME} PUBLIC -DFLOAT_TETWILD_MESH_PATH=\"${MESH_PATH}\")

# Compile extras only if this is a top-level project
if(FLOAT_TETWILD_TOPLEVEL_PROJECT)
	# Unit tests
	include(CTest)
	enable_testing()
	add_subdirectory(tests)
endif()
