include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(imgui_cmake_template_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(imgui_cmake_template_setup_options)
  option(imgui_cmake_template_ENABLE_HARDENING "Enable hardening" ON)
  option(imgui_cmake_template_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    imgui_cmake_template_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    imgui_cmake_template_ENABLE_HARDENING
    OFF)

  imgui_cmake_template_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR imgui_cmake_template_PACKAGING_MAINTAINER_MODE)
    option(imgui_cmake_template_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(imgui_cmake_template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(imgui_cmake_template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(imgui_cmake_template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(imgui_cmake_template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(imgui_cmake_template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(imgui_cmake_template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(imgui_cmake_template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(imgui_cmake_template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(imgui_cmake_template_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(imgui_cmake_template_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(imgui_cmake_template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(imgui_cmake_template_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(imgui_cmake_template_ENABLE_IPO "Enable IPO/LTO" ON)
    option(imgui_cmake_template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(imgui_cmake_template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(imgui_cmake_template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(imgui_cmake_template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(imgui_cmake_template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(imgui_cmake_template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(imgui_cmake_template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(imgui_cmake_template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(imgui_cmake_template_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(imgui_cmake_template_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(imgui_cmake_template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(imgui_cmake_template_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      imgui_cmake_template_ENABLE_IPO
      imgui_cmake_template_WARNINGS_AS_ERRORS
      imgui_cmake_template_ENABLE_USER_LINKER
      imgui_cmake_template_ENABLE_SANITIZER_ADDRESS
      imgui_cmake_template_ENABLE_SANITIZER_LEAK
      imgui_cmake_template_ENABLE_SANITIZER_UNDEFINED
      imgui_cmake_template_ENABLE_SANITIZER_THREAD
      imgui_cmake_template_ENABLE_SANITIZER_MEMORY
      imgui_cmake_template_ENABLE_UNITY_BUILD
      imgui_cmake_template_ENABLE_CLANG_TIDY
      imgui_cmake_template_ENABLE_CPPCHECK
      imgui_cmake_template_ENABLE_COVERAGE
      imgui_cmake_template_ENABLE_PCH
      imgui_cmake_template_ENABLE_CACHE)
  endif()

  imgui_cmake_template_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (imgui_cmake_template_ENABLE_SANITIZER_ADDRESS OR imgui_cmake_template_ENABLE_SANITIZER_THREAD OR imgui_cmake_template_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(imgui_cmake_template_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(imgui_cmake_template_global_options)
  if(imgui_cmake_template_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    imgui_cmake_template_enable_ipo()
  endif()

  imgui_cmake_template_supports_sanitizers()

  if(imgui_cmake_template_ENABLE_HARDENING AND imgui_cmake_template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR imgui_cmake_template_ENABLE_SANITIZER_UNDEFINED
       OR imgui_cmake_template_ENABLE_SANITIZER_ADDRESS
       OR imgui_cmake_template_ENABLE_SANITIZER_THREAD
       OR imgui_cmake_template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${imgui_cmake_template_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${imgui_cmake_template_ENABLE_SANITIZER_UNDEFINED}")
    imgui_cmake_template_enable_hardening(imgui_cmake_template_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(imgui_cmake_template_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(imgui_cmake_template_warnings INTERFACE)
  add_library(imgui_cmake_template_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  imgui_cmake_template_set_project_warnings(
    imgui_cmake_template_warnings
    ${imgui_cmake_template_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(imgui_cmake_template_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    imgui_cmake_template_configure_linker(imgui_cmake_template_options)
  endif()

  include(cmake/Sanitizers.cmake)
  imgui_cmake_template_enable_sanitizers(
    imgui_cmake_template_options
    ${imgui_cmake_template_ENABLE_SANITIZER_ADDRESS}
    ${imgui_cmake_template_ENABLE_SANITIZER_LEAK}
    ${imgui_cmake_template_ENABLE_SANITIZER_UNDEFINED}
    ${imgui_cmake_template_ENABLE_SANITIZER_THREAD}
    ${imgui_cmake_template_ENABLE_SANITIZER_MEMORY})

  set_target_properties(imgui_cmake_template_options PROPERTIES UNITY_BUILD ${imgui_cmake_template_ENABLE_UNITY_BUILD})

  if(imgui_cmake_template_ENABLE_PCH)
    target_precompile_headers(
      imgui_cmake_template_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(imgui_cmake_template_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    imgui_cmake_template_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(imgui_cmake_template_ENABLE_CLANG_TIDY)
    imgui_cmake_template_enable_clang_tidy(imgui_cmake_template_options ${imgui_cmake_template_WARNINGS_AS_ERRORS})
  endif()

  if(imgui_cmake_template_ENABLE_CPPCHECK)
    imgui_cmake_template_enable_cppcheck(${imgui_cmake_template_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(imgui_cmake_template_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    imgui_cmake_template_enable_coverage(imgui_cmake_template_options)
  endif()

  if(imgui_cmake_template_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(imgui_cmake_template_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(imgui_cmake_template_ENABLE_HARDENING AND NOT imgui_cmake_template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR imgui_cmake_template_ENABLE_SANITIZER_UNDEFINED
       OR imgui_cmake_template_ENABLE_SANITIZER_ADDRESS
       OR imgui_cmake_template_ENABLE_SANITIZER_THREAD
       OR imgui_cmake_template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    imgui_cmake_template_enable_hardening(imgui_cmake_template_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
