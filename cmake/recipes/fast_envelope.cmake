# Fast-Envelope (https://github.com/wangbolun300/fast-envelope)
# License: MIT
if(TARGET fast_envelope::fast_envelope)
    return()
endif()

message(STATUS "Third-party: creating target 'fast_envelope::fast_envelope'")

include(CPM)
CPMAddPackage("gh:wangbolun300/fast-envelope#520ee04b6c69a802db31d1fd3a3e6e382d10ef98")

add_library(fast_envelope::fast_envelope ALIAS FastEnvelope)