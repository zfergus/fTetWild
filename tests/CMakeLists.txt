################################################################################
# Tests
################################################################################

set(test_sources
	main.cpp
	tests.cpp
	test_predicates.cpp
	test_table.cpp
	# test_subdivision.cpp
	# test_tree.cpp
	# test_envelope.cpp
)


add_executable(unit_tests ${test_sources})

################################################################################
# Required Libraries
################################################################################

target_link_libraries(unit_tests PUBLIC ftetwild::ftetwild)

include(catch2)
target_link_libraries(unit_tests PUBLIC Catch2::Catch2WithMain)

include(ftetwild_warnings)
target_link_libraries(unit_tests PUBLIC ftetwild::warnings)

if(FLOAT_TETWILD_WITH_SANITIZERS)
	include(santizer)
	add_sanitizers(unit_tests)
endif()

################################################################################
# Compiler options
################################################################################

# set(DATA_DIR "${THIRD_PARTY_DIR}/data/")
# target_compile_definitions(unit_tests PUBLIC DATA_DIR=\"${DATA_DIR}\")

################################################################################
# Register tests
################################################################################

FetchContent_GetProperties(catch2)
list(APPEND CMAKE_MODULE_PATH ${catch2_SOURCE_DIR}/extras)
include(Catch)

# Register tests
set(PARSE_CATCH_TESTS_ADD_TO_CONFIGURE_DEPENDS ON)
catch_discover_tests(unit_tests)