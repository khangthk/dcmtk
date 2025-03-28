# Set build configuration to use for configuration tests
if(CMAKE_BUILD_TYPE)
  set(CMAKE_TRY_COMPILE_CONFIGURATION "${CMAKE_BUILD_TYPE}")
else()
  set(CMAKE_TRY_COMPILE_CONFIGURATION "Release")
endif()

# Select between built-in, external or no default dictionary support
if(DCMTK_DEFAULT_DICT STREQUAL "builtin")
  message(STATUS "Info: DCMTK will compile with built-in (compiled-in) default dictionary")
  set(DCM_DICT_DEFAULT 1)
  # No extra variable needed since its only evaluated in CMake files
elseif(DCMTK_DEFAULT_DICT STREQUAL "external")
  message(STATUS "Info: DCMTK will compile with external default dictionary")
  set(DCM_DICT_DEFAULT 2)
else()
  message(STATUS "Info: DCMTK will compile without any default dictionary")
  set(DCM_DICT_DEFAULT 0)
endif()


# Evaluation of old DCMDICTPATH environment variable (deprecation warning)
if(DEFINED DCMTK_ENABLE_BUILTIN_DICTIONARY)
  message(WARNING "Usage of DCMTK_ENABLE_BUILTIN_DICTIONARY has been deprecated, see DCMTK_DEFAULT_DICT")
endif()
if(DEFINED DCMTK_ENABLE_EXTERNAL_DICTIONARY)
  message(WARNING "Usage of DCMTK_ENABLE_EXTERNAL_DICTIONARY has been deprecated, see DCMTK_USE_DCMDICTPATH")
endif()

# Evaluation of DCMDICTPATH environment variable
if(DCMTK_USE_DCMDICTPATH)
  set(DCM_DICT_USE_DCMDICTPATH 1)
  message(STATUS "Info: DCMTK will load dictionaries defined by DCMDICTPATH environment variable")
else()
  set(DCM_DICT_USE_DCMDICTPATH "")
  message(STATUS "Info: DCMTK will not load dictionaries defined by DCMDICTPATH environment variable")
endif()

# Private tags
if(DCMTK_ENABLE_PRIVATE_TAGS)
  set(ENABLE_PRIVATE_TAGS 1)
  message(STATUS "Info: DCMTK's builtin private dictionary support will be enabled")
else()
  set(ENABLE_PRIVATE_TAGS "")
  message(STATUS "Info: DCMTK's builtin private dictionary support will be disabled")
endif()

# Thread support
if(DCMTK_WITH_THREADS)
  set(WITH_THREADS 1)
  message(STATUS "Info: Thread support will be enabled")
else()
  set(WITH_THREADS "")
  message(STATUS "Info: Thread support will be disabled")
endif()

# Wide char file I/O support
if(DCMTK_WIDE_CHAR_FILE_IO_FUNCTIONS)
  set(WIDE_CHAR_FILE_IO_FUNCTIONS 1)
  message(STATUS "Info: Wide char file I/O functions will be enabled")
else()
  set(WIDE_CHAR_FILE_IO_FUNCTIONS "")
  message(STATUS "Info: Wide char file I/O functions will be disabled")
endif()

# Wide char main function
if(DCMTK_WIDE_CHAR_MAIN_FUNCTION)
  set(WIDE_CHAR_MAIN_FUNCTION 1)
  message(STATUS "Info: Wide char main function for command line tools will be enabled")
else()
  set(WIDE_CHAR_MAIN_FUNCTION "")
  message(STATUS "Info: Wide char main function for command line tools will be disabled")
endif()

if(NOT DCMTK_ENABLE_CHARSET_CONVERSION)
  set(DCMTK_ENABLE_CHARSET_CONVERSION_DOCSTRING "Select character set conversion implementation.")
  set(DCMTK_ENABLE_CHARSET_CONVERSION "oficonv" CACHE STRING "${DCMTK_ENABLE_CHARSET_CONVERSION_DOCSTRING}")
endif()

set(DCMTK_ENABLE_CHARSET_CONVERSION_ALTERNATIVES)
list(APPEND DCMTK_ENABLE_CHARSET_CONVERSION_ALTERNATIVES "oficonv")
if(DCMTK_WITH_ICONV)
  list(APPEND DCMTK_ENABLE_CHARSET_CONVERSION_ALTERNATIVES "libiconv")
endif()
if(DCMTK_WITH_STDLIBC_ICONV)
  list(APPEND DCMTK_ENABLE_CHARSET_CONVERSION_ALTERNATIVES "stdlibc (iconv)")
endif()
set_property(CACHE DCMTK_ENABLE_CHARSET_CONVERSION PROPERTY STRINGS ${DCMTK_ENABLE_CHARSET_CONVERSION_ALTERNATIVES} "<disabled>")

if(DCMTK_ENABLE_CHARSET_CONVERSION STREQUAL "oficonv" OR DCMTK_ENABLE_CHARSET_CONVERSION STREQUAL "DCMTK_CHARSET_CONVERSION_OFICONV")
  message(STATUS "Info: Building DCMTK with character set conversion support using built-in oficonv module")
  set(DCMTK_ENABLE_CHARSET_CONVERSION "DCMTK_CHARSET_CONVERSION_OFICONV")
  set(CHARSET_CONVERSION_LIBS)
elseif(DCMTK_ENABLE_CHARSET_CONVERSION STREQUAL "libiconv" OR DCMTK_ENABLE_CHARSET_CONVERSION STREQUAL "DCMTK_CHARSET_CONVERSION_ICONV")
  message(STATUS "Info: Building DCMTK with character set conversion support using libiconv")
  set(DCMTK_ENABLE_CHARSET_CONVERSION "DCMTK_CHARSET_CONVERSION_ICONV")
  set(CHARSET_CONVERSION_LIBS ${LIBICONV_LIBS})
elseif(DCMTK_ENABLE_CHARSET_CONVERSION STREQUAL "stdlibc (iconv)" OR DCMTK_ENABLE_CHARSET_CONVERSION STREQUAL "DCMTK_CHARSET_CONVERSION_STDLIBC_ICONV")
  message(STATUS "Info: Building DCMTK with character set conversion support using builtin iconv functions from the C standard library")
  set(DCMTK_ENABLE_CHARSET_CONVERSION "DCMTK_CHARSET_CONVERSION_STDLIBC_ICONV")
else()
  message(STATUS "Info: Building DCMTK without character set conversion support")
  set(DCMTK_ENABLE_CHARSET_CONVERSION OFF)
endif()

# Configure file

# Windows being windows, it lies about its processor type to 32 bit binaries
set(SYSTEM_PROCESSOR "$ENV{PROCESSOR_ARCHITEW6432}")
if(NOT SYSTEM_PROCESSOR)
  if(WIN32 AND NOT CYGWIN)
    if(CMAKE_GENERATOR_PLATFORM)
      set(SYSTEM_PROCESSOR "${CMAKE_GENERATOR_PLATFORM}")
    elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
      set(SYSTEM_PROCESSOR "x64")
    elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
      set(SYSTEM_PROCESSOR "Win32")
    endif()
  else()
    set(SYSTEM_PROCESSOR "${CMAKE_SYSTEM_PROCESSOR}")
  endif()
endif()
# CMake doesn't provide a configure-style system type string
set(CANONICAL_HOST_TYPE "${SYSTEM_PROCESSOR}-${CMAKE_SYSTEM_NAME}")
DCMTK_UNSET(SYSTEM_PROCESSOR)

# Define the complete package version name that will be used as a subdirectory
# name for the installation of configuration files, data files and documents.
if(DCMTK_PACKAGE_VERSION_SUFFIX STREQUAL "+")
  # development version
  set(DCMTK_COMPLETE_PACKAGE_VERSION "${DCMTK_PACKAGE_VERSION}-${DCMTK_PACKAGE_DATE}")
else()
  # release version
  set(DCMTK_COMPLETE_PACKAGE_VERSION "${DCMTK_PACKAGE_VERSION}${DCMTK_PACKAGE_VERSION_SUFFIX}")
endif()

# Configure dictionary path and install prefix
if(WIN32 AND NOT CYGWIN)
  # create cache variable, default value is "OFF"
  set(DCMTK_USE_WIN32_PROGRAMDATA OFF CACHE BOOL "Install configuration and data files in %PROGRAMDATA%")

  # Set DCMTK_PREFIX needed within some code. Be sure that all / are replaced by \\.
  set(DCMTK_PREFIX "${CMAKE_INSTALL_PREFIX}")
  string(REGEX REPLACE "/" "\\\\\\\\" DCMTK_PREFIX "${DCMTK_PREFIX}")
  # Set path and multiple path separator being used in dictionary code etc.
  set(PATH_SEPARATOR "\\\\")
  set(ENVIRONMENT_PATH_SEPARATOR ";")

  # Set default directory for configuration and support data.
  if(DCMTK_USE_WIN32_PROGRAMDATA)
    set(PROGRAMDATA "$ENV{PROGRAMDATA}")
    string(REPLACE "\\" "/" PROGRAMDATA "${PROGRAMDATA}")
    set(CMAKE_INSTALL_FULL_SYSCONFDIR "${PROGRAMDATA}/dcmtk-${DCMTK_COMPLETE_PACKAGE_VERSION}/etc")
    set(CMAKE_INSTALL_FULL_DATADIR    "${PROGRAMDATA}/dcmtk-${DCMTK_COMPLETE_PACKAGE_VERSION}/share")
    set(CMAKE_INSTALL_FULL_DOCDIR     "${PROGRAMDATA}/dcmtk-${DCMTK_COMPLETE_PACKAGE_VERSION}/doc")

    # These variables are defined as macros in osconfig.h and must end with a path separator
    set(DCMTK_DEFAULT_CONFIGURATION_DIR "%PROGRAMDATA%\\\\dcmtk-${DCMTK_COMPLETE_PACKAGE_VERSION}\\\\etc${PATH_SEPARATOR}")
    set(DCMTK_DEFAULT_SUPPORT_DATA_DIR  "%PROGRAMDATA%\\\\dcmtk-${DCMTK_COMPLETE_PACKAGE_VERSION}\\\\share${PATH_SEPARATOR}")
  else()
    set(CMAKE_INSTALL_DATADIR "${CMAKE_INSTALL_DATADIR}/dcmtk-${DCMTK_COMPLETE_PACKAGE_VERSION}")
    set(CMAKE_INSTALL_DOCDIR "${CMAKE_INSTALL_DOCDIR}-${DCMTK_COMPLETE_PACKAGE_VERSION}")
    set(DCMTK_DEFAULT_CONFIGURATION_DIR "")
    set(DCMTK_DEFAULT_SUPPORT_DATA_DIR "")
  endif()

  # Set dictionary path to the data dir inside install main dir (prefix)
  if(DCMTK_DEFAULT_DICT STREQUAL "external")
    if(DCMTK_USE_WIN32_PROGRAMDATA)
      set(DCM_DICT_DEFAULT_PATH "${CMAKE_INSTALL_FULL_DATADIR}\\\\dicom.dic")
    else()
      set(DCM_DICT_DEFAULT_PATH "${DCMTK_PREFIX}\\\\${CMAKE_INSTALL_DATADIR}\\\\dcmtk\\\\dicom.dic")
    endif()

    # If private dictionary should be utilized, add it to default dictionary path.
    if(ENABLE_PRIVATE_TAGS)
      if(DCMTK_USE_WIN32_PROGRAMDATA)
        set(DCM_DICT_DEFAULT_PATH "${DCM_DICT_DEFAULT_PATH};${CMAKE_INSTALL_FULL_DATADIR}\\\\private.dic")
      else()
        set(DCM_DICT_DEFAULT_PATH "${DCM_DICT_DEFAULT_PATH};${DCMTK_PREFIX}\\\\${CMAKE_INSTALL_DATADIR}\\\\dcmtk\\\\private.dic")
      endif()
    endif()

     # Again, for Windows strip all / from path and replace it with \\.
    string(REGEX REPLACE "/" "\\\\\\\\" DCM_DICT_DEFAULT_PATH "${DCM_DICT_DEFAULT_PATH}")
  else()
    set(DCM_DICT_DEFAULT_PATH "")
  endif()
else()
  # Set DCMTK_PREFIX needed within some code.
  set(DCMTK_PREFIX "${CMAKE_INSTALL_PREFIX}")
  # Set path and multiple path separator being used in dictionary code etc.
  set(PATH_SEPARATOR "/")
  set(ENVIRONMENT_PATH_SEPARATOR ":")

  # Modify the installation paths for configuration files, data files and documents
  # by adding a subdirectory with the DCMTK name and version number
  set(CMAKE_INSTALL_SYSCONFDIR "${CMAKE_INSTALL_SYSCONFDIR}/dcmtk-${DCMTK_COMPLETE_PACKAGE_VERSION}")
  set(CMAKE_INSTALL_DATADIR "${CMAKE_INSTALL_DATADIR}/dcmtk-${DCMTK_COMPLETE_PACKAGE_VERSION}")
  set(CMAKE_INSTALL_DOCDIR "${CMAKE_INSTALL_DOCDIR}-${DCMTK_COMPLETE_PACKAGE_VERSION}")

  # These variables are defined as macros in osconfig.h and must end with a path separator
  if(CMAKE_VERSION VERSION_LESS 3.20.0)
    # CMake versions prior to 3.20 expect the third parameter to be passed in ${dir}
    set(dir "SYSCONFDIR")
    GNUInstallDirs_get_absolute_install_dir(DCMTK_DEFAULT_CONFIGURATION_DIR CMAKE_INSTALL_SYSCONFDIR)
    set(dir "BINDIR")
    GNUInstallDirs_get_absolute_install_dir(DCMTK_DEFAULT_SUPPORT_DATA_DIR CMAKE_INSTALL_DATADIR)
  else()
    GNUInstallDirs_get_absolute_install_dir(DCMTK_DEFAULT_CONFIGURATION_DIR CMAKE_INSTALL_SYSCONFDIR SYSCONFDIR)
    GNUInstallDirs_get_absolute_install_dir(DCMTK_DEFAULT_SUPPORT_DATA_DIR CMAKE_INSTALL_DATADIR BINDIR)
  endif()
  set(DCMTK_DEFAULT_CONFIGURATION_DIR "${DCMTK_DEFAULT_CONFIGURATION_DIR}/")
  set(DCMTK_DEFAULT_SUPPORT_DATA_DIR "${DCMTK_DEFAULT_SUPPORT_DATA_DIR}/")

  # Set dictionary path to the data dir inside install main dir (prefix).
  if(DCMTK_DEFAULT_DICT STREQUAL "external")
    set(DCM_DICT_DEFAULT_PATH "${DCMTK_DEFAULT_SUPPORT_DATA_DIR}dicom.dic")
    # If private dictionary should be utilized, add it to default dictionary path.
    if(ENABLE_PRIVATE_TAGS)
      set(DCM_DICT_DEFAULT_PATH "${DCM_DICT_DEFAULT_PATH}:${DCMTK_DEFAULT_SUPPORT_DATA_DIR}private.dic")
    endif()
  else()
    set(DCM_DICT_DEFAULT_PATH "")
  endif()
endif()

# Check the sizes of various types
include(CheckTypeSize)
CHECK_TYPE_SIZE("int" SIZEOF_INT)
CHECK_TYPE_SIZE("long" SIZEOF_LONG)
CHECK_TYPE_SIZE("void*" SIZEOF_VOID_P)

# Check for include files, libraries, and functions
include("${DCMTK_CMAKE_INCLUDE}CMake/dcmtkTryCompile.cmake")
include("${DCMTK_CMAKE_INCLUDE}CMake/dcmtkTryRun.cmake")
include("${CMAKE_ROOT}/Modules/CheckIncludeFileCXX.cmake")
include("${CMAKE_ROOT}/Modules/CheckIncludeFiles.cmake")
include("${CMAKE_ROOT}/Modules/CheckSymbolExists.cmake")
include("${CMAKE_ROOT}/Modules/CheckFunctionExists.cmake")
include("${CMAKE_ROOT}/Modules/CheckLibraryExists.cmake")
include("${DCMTK_CMAKE_INCLUDE}CMake/CheckFunctionWithHeaderExists.cmake")
include(CheckCXXSymbolExists OPTIONAL)
if(NOT COMMAND CHECK_CXX_SYMBOL_EXISTS)
  # fallback implementation for old CMake Versions
  function(CHECK_CXX_SYMBOL_EXISTS SYMBOL FILES VAR)
    set(CODE)
    foreach(FILE ${FILES})
      set(CODE "${CODE}#include <${FILE}>\n")
    endforeach()
    set(CODE "${CODE}\nint main(int argc, char** argv)\n{\n  (void)argv;\n#ifndef ${SYMBOL}\n  return ((int*)(&${SYMBOL}))[argc];\n#else\n  (void)argc;\n  return 0;\n#endif\n}\n")
    DCMTK_TRY_COMPILE("${VAR}" "the compiler supports ${SYMBOL}" "${CODE}")
  endfunction()
endif()

foreach(FUNC "__FUNCTION__" "__PRETTY_FUNCTION__" "__func__")
  CHECK_SYMBOL_EXISTS("${FUNC}" "" "HAVE_${FUNC}_C_MACRO")
  # test if the C++ compiler also supports them (e.g. SunPro doesn't)
  CHECK_CXX_SYMBOL_EXISTS("${FUNC}" "" "HAVE_${FUNC}_CXX_MACRO")
  if(HAVE_${FUNC}_C_MACRO AND HAVE_${FUNC}_CXX_MACRO)
    set("HAVE_${FUNC}_MACRO" 1 CACHE INTERNAL "Have symbol ${FUNC}" FORCE)
  else()
    set("HAVE_${FUNC}_MACRO" CACHE INTERNAL "Have symbol ${FUNC}" FORCE)
  endif()
endforeach()

# prepare include directories for 3rdparty libraries before performing
# header searches
if(ZLIB_INCDIR)
  list(APPEND CMAKE_REQUIRED_INCLUDES "${ZLIB_INCDIR}")
endif()

if(ZLIB_INCLUDE_DIRS)
  list(APPEND CMAKE_REQUIRED_INCLUDES "${ZLIB_INCLUDE_DIRS}")
endif()

if(LIBPNG_INCDIR)
  list(APPEND CMAKE_REQUIRED_INCLUDES "${LIBPNG_INCDIR}")
endif()

if(PNG_INCLUDE_DIR)
  list(APPEND CMAKE_REQUIRED_INCLUDES "${PNG_INCLUDE_DIR}")
endif()

if(OPENSSL_INCDIR)
  list(APPEND CMAKE_REQUIRED_INCLUDES "${OPENSSL_INCDIR}")
endif()

if(OPENSSL_INCLUDE_DIR)
  list(APPEND CMAKE_REQUIRED_INCLUDES "${OPENSSL_INCLUDE_DIR}")
endif()

# For Windows, hardcode these values to avoid long search times
if(WIN32 AND NOT CYGWIN)
  CHECK_INCLUDE_FILE_CXX("windows.h" HAVE_WINDOWS_H)
  CHECK_INCLUDE_FILE_CXX("winsock.h" HAVE_WINSOCK_H)
endif()

  CHECK_INCLUDE_FILE_CXX("alloca.h" HAVE_ALLOCA_H)
  CHECK_INCLUDE_FILE_CXX("arpa/inet.h" HAVE_ARPA_INET_H)
  CHECK_INCLUDE_FILE_CXX("cstdint" HAVE_CSTDINT)
  CHECK_INCLUDE_FILE_CXX("dirent.h" HAVE_DIRENT_H)
  CHECK_INCLUDE_FILE_CXX("err.h" HAVE_ERR_H)
  CHECK_INCLUDE_FILE_CXX("fnmatch.h" HAVE_FNMATCH_H)
  CHECK_INCLUDE_FILE_CXX("grp.h" HAVE_GRP_H)
  CHECK_INCLUDE_FILE_CXX("ieeefp.h" HAVE_IEEEFP_H)
  CHECK_INCLUDE_FILE_CXX("io.h" HAVE_IO_H)
  CHECK_INCLUDE_FILE_CXX("langinfo.h" HAVE_LANGINFO_H)
  CHECK_INCLUDE_FILE_CXX("libc.h" HAVE_LIBC_H)
  CHECK_INCLUDE_FILE_CXX("mqueue.h" HAVE_MQUEUE_H)
  CHECK_INCLUDE_FILE_CXX("netdb.h" HAVE_NETDB_H)
  CHECK_INCLUDE_FILE_CXX("png.h" HAVE_PNG_H)
  CHECK_INCLUDE_FILE_CXX("process.h" HAVE_PROCESS_H)
  CHECK_INCLUDE_FILE_CXX("pthread.h" HAVE_PTHREAD_H)
  CHECK_INCLUDE_FILE_CXX("pwd.h" HAVE_PWD_H)
  CHECK_INCLUDE_FILE_CXX("semaphore.h" HAVE_SEMAPHORE_H)
  CHECK_INCLUDE_FILE_CXX("strings.h" HAVE_STRINGS_H)
  CHECK_INCLUDE_FILE_CXX("synch.h" HAVE_SYNCH_H)
  CHECK_INCLUDE_FILE_CXX("sys/dir.h" HAVE_SYS_DIR_H)
  CHECK_INCLUDE_FILE_CXX("sys/file.h" HAVE_SYS_FILE_H)
  CHECK_INCLUDE_FILE_CXX("sys/mman.h" HAVE_SYS_MMAN_H)
  CHECK_INCLUDE_FILE_CXX("sys/msg.h" HAVE_SYS_MSG_H)
  CHECK_INCLUDE_FILE_CXX("sys/param.h" HAVE_SYS_PARAM_H)
  CHECK_INCLUDE_FILE_CXX("sys/queue.h" HAVE_SYS_QUEUE_H)
  CHECK_INCLUDE_FILE_CXX("sys/resource.h" HAVE_SYS_RESOURCE_H)
  CHECK_INCLUDE_FILE_CXX("sys/select.h" HAVE_SYS_SELECT_H)
  CHECK_INCLUDE_FILE_CXX("sys/socket.h" HAVE_SYS_SOCKET_H)
  CHECK_INCLUDE_FILE_CXX("sys/syscall.h" HAVE_SYS_SYSCALL_H)
  CHECK_INCLUDE_FILE_CXX("sys/systeminfo.h" HAVE_SYS_SYSTEMINFO_H)
  CHECK_INCLUDE_FILE_CXX("sys/time.h" HAVE_SYS_TIME_H)
  CHECK_INCLUDE_FILE_CXX("sys/timeb.h" HAVE_SYS_TIMEB_H)
  CHECK_INCLUDE_FILE_CXX("sys/un.h" HAVE_SYS_UN_H)
  CHECK_INCLUDE_FILE_CXX("sys/utime.h" HAVE_SYS_UTIME_H)
  CHECK_INCLUDE_FILE_CXX("sys/utsname.h" HAVE_SYS_UTSNAME_H)
  CHECK_INCLUDE_FILE_CXX("sys/wait.h" HAVE_SYS_WAIT_H)
  CHECK_INCLUDE_FILE_CXX("syslog.h" HAVE_SYSLOG_H)
  CHECK_INCLUDE_FILE_CXX("thread.h" HAVE_THREAD_H)
  CHECK_INCLUDE_FILE_CXX("unistd.h" HAVE_UNISTD_H)
  CHECK_INCLUDE_FILE_CXX("unix.h" HAVE_UNIX_H)
  CHECK_INCLUDE_FILE_CXX("utime.h" HAVE_UTIME_H)
  CHECK_INCLUDE_FILE_CXX("type_traits" HAVE_TYPE_TRAITS)
  CHECK_INCLUDE_FILE_CXX("atomic" HAVE_ATOMIC)

if(NOT APPLE)
  # poll on macOS is unreliable, it first did not exist, then was broken until
  # fixed in 10.9 only to break again in 10.12.
  CHECK_INCLUDE_FILE_CXX("poll.h" DCMTK_HAVE_POLL)
  if(DCMTK_HAVE_POLL)
    add_definitions(-DDCMTK_HAVE_POLL=1)
  endif()
endif()

  # This mimics the autoconf test. There are systems out there
  # (e.g. FreeBSD and NeXT) where tcp.h can't be compiled on its own.
  # This one is needed to make FreeBSD happy
  set(TCP_H_DEPS "sys/types.h")
  CHECK_INCLUDE_FILES("${TCP_H_DEPS};netinet/in_systm.h" HAVE_NETINET_IN_SYSTM_H)
  if(HAVE_NETINET_IN_SYSTM_H)
    set(TCP_H_DEPS "${TCP_H_DEPS};netinet/in_systm.h")
  endif()
  CHECK_INCLUDE_FILES("${TCP_H_DEPS};netinet/in.h" HAVE_NETINET_IN_H)
  if(HAVE_NETINET_IN_H)
    set(TCP_H_DEPS "${TCP_H_DEPS};netinet/in.h")
  endif()
  CHECK_INCLUDE_FILES("${TCP_H_DEPS};netinet/tcp.h" HAVE_NETINET_TCP_H)

  if(NOT HAVE_PNG_H)
    # <png.h> is unavailable, so test if we need to include it as <libpng/png.h>
    CHECK_INCLUDE_FILE_CXX("libpng/png.h" HAVE_LIBPNG_PNG_H)
  else()
    # ensure including <png.h> is preferred
    DCMTK_UNSET_CACHE(HAVE_LIBPNG_PNG_H)
  endif()

  # There is no CMake macro to take care of these yet

  if(WIN32 AND NOT CYGWIN AND NOT MINGW)
    set(HAVE_NO_TYPEDEF_SSIZE_T TRUE)
    set(HAVE_NO_TYPEDEF_PID_T TRUE)
  else()
    set(HAVE_NO_TYPEDEF_PID_T FALSE)
  endif()

  set(HEADERS)

  if(HAVE_IEEEFP_H)
    set(HEADERS ${HEADERS} ieeefp.h)
  endif()

  if(HAVE_IO_H)
    set(HEADERS ${HEADERS} io.h)
  endif()

  set(HEADERS ${HEADERS} math.h)

  if(HAVE_LIBC_H)
    set(HEADERS ${HEADERS} libc.h)
  endif()

  if(HAVE_THREAD_H)
    set(HEADERS ${HEADERS} thread.h)
  endif()

  if(HAVE_PROCESS_H)
    set(HEADERS ${HEADERS} process.h)
  endif()

  if(HAVE_PTHREAD_H)
    set(HEADERS ${HEADERS} pthread.h)
  endif()

  if(HAVE_UNISTD_H)
    set(HEADERS ${HEADERS} unistd.h)
  endif()

  set(HEADERS ${HEADERS} stdlib.h)
  set(HEADERS ${HEADERS} stdint.h)
  set(HEADERS ${HEADERS} stddef.h)

  if(HAVE_NETDB_H)
    set(HEADERS ${HEADERS} netdb.h)
  endif()

  if(HAVE_SYS_FILE_H)
    set(HEADERS ${HEADERS} sys/file.h)
  endif()

  set(HEADERS ${HEADERS} string.h)

  if(HAVE_STRINGS_H)
    set(HEADERS ${HEADERS} strings.h)
  endif()

  if(HAVE_SYS_WAIT_H)
    set(HEADERS ${HEADERS} sys/wait.h)
  endif()

  if(HAVE_SYS_TIME_H)
    set(HEADERS ${HEADERS} sys/time.h)
  endif()

  if(HAVE_SYS_RESOURCE_H)
    set(HEADERS ${HEADERS} sys/resource.h)
  endif()

  set(HEADERS ${HEADERS} sys/types.h)

  if(HAVE_SYS_SOCKET_H)
    set(HEADERS ${HEADERS} sys/socket.h)
  endif()

  set(HEADERS ${HEADERS} sys/stat.h)

  if(HAVE_SYS_TIMEB_H)
    set(HEADERS ${HEADERS} sys/timeb.h)
  endif()

  set(HEADERS ${HEADERS} stdarg.h)

  set(HEADERS ${HEADERS} stdio.h)

  if(HAVE_SYS_SELECT_H)
    set(HEADERS ${HEADERS} sys/select.h)
  endif()

  if(HAVE_WINDOWS_H)
    # also add winsock2.h and ws2tcpip.h that are available since Windows NT 4.0
    set(HEADERS ${HEADERS} winsock2.h ws2tcpip.h windows.h)
  endif()

  if(HAVE_GRP_H)
    set(HEADERS ${HEADERS} grp.h)
  endif()

  if(HAVE_PWD_H)
    set(HEADERS ${HEADERS} pwd.h)
  endif()

  if(HAVE_DIRENT_H)
    set(HEADERS ${HEADERS} dirent.h)
  endif()

  if(HAVE_SYS_SYSCALL_H)
    set(HEADERS ${HEADERS} sys/syscall.h)
  endif()

  if(HAVE_WINSOCK_H)
    set(HEADERS ${HEADERS} winsock.h)
    set(CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES} iphlpapi ws2_32 netapi32 wsock32)
  endif()

  set(HEADERS ${HEADERS} fenv.h)

  # std::vsnprintf and std::vsnprintf need the C++ version of the headers.
  # We just assume they exist when the C version was found
  set(CXXHEADERS)
  set(CXXHEADERS ${CXXHEADERS} cmath)
  set(CXXHEADERS ${CXXHEADERS} cstdio)
  set(CXXHEADERS ${CXXHEADERS} cstdarg)
  set(CXXHEADERS ${CXXHEADERS} cstddef)
  set(CXXHEADERS ${CXXHEADERS} iostream)

  if(HAVE_CSTDINT)
    set(CXXHEADERS ${CXXHEADERS} cstdint)
  endif()

  if(WIN32)
    # CHECK_FUNCTION_EXISTS does not work correctly on Windows (due to symbol name mangling)
    # use CHECK_SYMBOL_EXISTS instead
    macro(CHECK_FUNCTION_EXISTS FUNCTION VAR)
      check_symbol_exists("${FUNCTION}" "${HEADERS}" "${VAR}")
    endmacro()
  endif()

  CHECK_FUNCTION_EXISTS(_findfirst HAVE__FINDFIRST)
  CHECK_FUNCTION_EXISTS(_set_output_format HAVE__SET_OUTPUT_FORMAT)
  CHECK_FUNCTION_EXISTS(atoll HAVE_ATOLL)
  CHECK_FUNCTION_EXISTS(cuserid HAVE_CUSERID)
  CHECK_FUNCTION_EXISTS(fgetln HAVE_FGETLN)
  CHECK_FUNCTION_EXISTS(flock HAVE_FLOCK)
  CHECK_FUNCTION_EXISTS(fork HAVE_FORK)
  CHECK_FUNCTION_EXISTS(fseeko HAVE_FSEEKO)
  CHECK_FUNCTION_EXISTS(ftime HAVE_FTIME)
  CHECK_FUNCTION_EXISTS(geteuid HAVE_GETEUID)
  CHECK_FUNCTION_EXISTS(getgrnam HAVE_GETGRNAM)
  CHECK_FUNCTION_EXISTS(gethostbyaddr_r HAVE_GETHOSTBYADDR_R)
  CHECK_FUNCTION_EXISTS(gethostbyname_r HAVE_GETHOSTBYNAME_R)
  CHECK_FUNCTION_EXISTS(gethostid HAVE_GETHOSTID)
  CHECK_FUNCTION_EXISTS(getlogin HAVE_GETLOGIN)
  CHECK_FUNCTION_EXISTS(getlogin_r HAVE_GETLOGIN_R)
  CHECK_FUNCTION_EXISTS(getpwnam HAVE_GETPWNAM)
  CHECK_FUNCTION_EXISTS(gettimeofday HAVE_GETTIMEOFDAY)
  CHECK_FUNCTION_EXISTS(getuid HAVE_GETUID)
  CHECK_FUNCTION_EXISTS(gmtime_r HAVE_GMTIME_R)
  CHECK_FUNCTION_EXISTS(localtime_r HAVE_LOCALTIME_R)
  CHECK_FUNCTION_EXISTS(lockf HAVE_LOCKF)
  CHECK_FUNCTION_EXISTS(lstat HAVE_LSTAT)
  CHECK_FUNCTION_EXISTS(malloc_debug HAVE_MALLOC_DEBUG)
  CHECK_FUNCTION_EXISTS(mkstemp HAVE_MKSTEMP)
  CHECK_FUNCTION_EXISTS(nanosleep HAVE_NANOSLEEP)
  CHECK_FUNCTION_EXISTS(setuid HAVE_SETUID)
  CHECK_FUNCTION_EXISTS(sleep HAVE_SLEEP)
  CHECK_FUNCTION_EXISTS(strlcat HAVE_STRLCAT)
  CHECK_FUNCTION_EXISTS(strlcpy HAVE_STRLCPY)
  CHECK_FUNCTION_EXISTS(sysinfo HAVE_SYSINFO)
  CHECK_FUNCTION_EXISTS(uname HAVE_UNAME)
  CHECK_FUNCTION_EXISTS(usleep HAVE_USLEEP)
  CHECK_FUNCTION_EXISTS(waitpid HAVE_WAITPID)

  CHECK_SYMBOL_EXISTS(strcasestr "string.h" HAVE_PROTOTYPE_STRCASESTR)

  CHECK_FUNCTIONWITHHEADER_EXISTS(flock "${HEADERS}" HAVE_PROTOTYPE_FLOCK)
  CHECK_FUNCTIONWITHHEADER_EXISTS(gethostbyname_r "${HEADERS}" HAVE_PROTOTYPE_GETHOSTBYNAME_R)
  CHECK_FUNCTIONWITHHEADER_EXISTS(gethostbyaddr_r "${HEADERS}" HAVE_PROTOTYPE_GETHOSTBYADDR_R)
  CHECK_FUNCTIONWITHHEADER_EXISTS(gethostid "${HEADERS}" HAVE_PROTOTYPE_GETHOSTID)
  CHECK_FUNCTIONWITHHEADER_EXISTS(waitpid "${HEADERS}" HAVE_PROTOTYPE_WAITPID)
  CHECK_FUNCTIONWITHHEADER_EXISTS(usleep "${HEADERS}" HAVE_PROTOTYPE_USLEEP)
# the following functions are partially C99 and partially nonstandard and may
# not be defined in the standard C++ headers.
  CHECK_FUNCTIONWITHHEADER_EXISTS(_vsnprintf_s "${HEADERS}" HAVE__VSNPRINTF_S)
  CHECK_FUNCTIONWITHHEADER_EXISTS(vfprintf_s "${HEADERS}" HAVE_VFPRINTF_S)
  CHECK_FUNCTIONWITHHEADER_EXISTS(vsprintf_s "${HEADERS}" HAVE_VSPRINTF_S)
  CHECK_FUNCTIONWITHHEADER_EXISTS(std::vsnprintf "${CXXHEADERS}" HAVE_PROTOTYPE_STD__VSNPRINTF)
  CHECK_FUNCTIONWITHHEADER_EXISTS(_stricmp "${HEADERS}" HAVE_PROTOTYPE__STRICMP)
  CHECK_FUNCTIONWITHHEADER_EXISTS(gettimeofday "${HEADERS}" HAVE_PROTOTYPE_GETTIMEOFDAY)
  CHECK_FUNCTIONWITHHEADER_EXISTS(strcasecmp "${HEADERS}" HAVE_PROTOTYPE_STRCASECMP)
  CHECK_FUNCTIONWITHHEADER_EXISTS(strncasecmp "${HEADERS}" HAVE_PROTOTYPE_STRNCASECMP)
  CHECK_FUNCTIONWITHHEADER_EXISTS(strerror_r "${HEADERS}" HAVE_PROTOTYPE_STRERROR_R)
  CHECK_FUNCTIONWITHHEADER_EXISTS(SYS_gettid "${HEADERS}" HAVE_SYS_GETTID)
  CHECK_FUNCTIONWITHHEADER_EXISTS(pthread_rwlock_init "${HEADERS}" HAVE_PTHREAD_RWLOCK)
  CHECK_FUNCTIONWITHHEADER_EXISTS("__sync_add_and_fetch((int*)0,0)" "${HEADERS}" HAVE_SYNC_ADD_AND_FETCH)
  CHECK_FUNCTIONWITHHEADER_EXISTS("__sync_sub_and_fetch((int*)0,0)" "${HEADERS}" HAVE_SYNC_SUB_AND_FETCH)
  CHECK_FUNCTIONWITHHEADER_EXISTS("InterlockedIncrement((long*)0)" "${HEADERS}" HAVE_INTERLOCKED_INCREMENT)
  CHECK_FUNCTIONWITHHEADER_EXISTS("InterlockedDecrement((long*)0)" "${HEADERS}" HAVE_INTERLOCKED_DECREMENT)
  CHECK_FUNCTIONWITHHEADER_EXISTS("getgrnam_r((char*)0,(group*)0,(char*)0,0,(group**)0)" "${HEADERS}" HAVE_GETGRNAM_R)
  CHECK_FUNCTIONWITHHEADER_EXISTS("getpwnam_r((char*)0,(passwd*)0,(char*)0,0,(passwd**)0)" "${HEADERS}" HAVE_GETPWNAM_R)
  CHECK_FUNCTIONWITHHEADER_EXISTS("readdir_r((DIR*)0,(dirent*)0,(dirent**)0)" "${HEADERS}" HAVE_READDIR_R)
  CHECK_FUNCTIONWITHHEADER_EXISTS("readdir_r((DIR*)0,(dirent*)0)" "${HEADERS}" HAVE_OLD_READDIR_R)
  CHECK_FUNCTIONWITHHEADER_EXISTS("&passwd::pw_gecos" "${HEADERS}" HAVE_PASSWD_GECOS)
  CHECK_FUNCTIONWITHHEADER_EXISTS("TryAcquireSRWLockShared((PSRWLOCK)0)" "${HEADERS}" HAVE_PROTOTYPE_TRYACQUIRESRWLOCKSHARED)

  # Check for some type definitions needed by JasPer and defines them if necessary
  # Even if not functions but types are looked for, the script works fine.
  # "definition" is an (exchangeable) identifier that is needed for successful compile test
  CHECK_FUNCTIONWITHHEADER_EXISTS("long long definition" "${HEADERS}" HAVE_LONG_LONG)
  CHECK_FUNCTIONWITHHEADER_EXISTS("unsigned long long definition" "${HEADERS}" HAVE_UNSIGNED_LONG_LONG)
  CHECK_FUNCTIONWITHHEADER_EXISTS("int64_t definition" "${HEADERS}" HAVE_INT64_T)
  CHECK_FUNCTIONWITHHEADER_EXISTS("uint64_t definition" "${HEADERS}" HAVE_UINT64_T)

  # char16_t is only supported since C++11
  CHECK_FUNCTIONWITHHEADER_EXISTS("char16_t definition" "${HEADERS}" HAVE_CHAR16_T)

  # File access stuff
  # fpos64_t and off64_t are not available in the C++ headers
  CHECK_FUNCTIONWITHHEADER_EXISTS("fpos64_t definition" "${HEADERS}" HAVE_FPOS64_T)
  CHECK_FUNCTIONWITHHEADER_EXISTS("off64_t definition" "${HEADERS}" HAVE_OFF64_T)
  # Check if the POSIX functions are available (even on Windows). They are preferred
  # to the Microsoft specific functions on compilers like MinGW.
  # popen and pclose are nonstandard and may not be available in the C++ headers
  CHECK_FUNCTIONWITHHEADER_EXISTS("popen" "${HEADERS}" HAVE_POPEN)
  CHECK_FUNCTIONWITHHEADER_EXISTS("pclose" "${HEADERS}" HAVE_PCLOSE)

if(HAVE_LOCKF AND ANDROID)
  # When Android introduced lockf, they forgot to put the constants like F_LOCK in the
  # appropriate headers, this tests if they are defined and disables lockf if they are not
  CHECK_FUNCTIONWITHHEADER_EXISTS("lockf(0, F_LOCK, 0)" "${HEADERS}" HAVE_LOCKF_CONSTANTS)
  if(NOT HAVE_LOCKF_CONSTANTS)
    set(HAVE_LOCKF FALSE CACHE INTERNAL "lockf implementation is broken")
  endif()
endif()

# Tests that require a try-compile

# We are using DCMTK_NO_TRY_RUN to disable the try_run parts, and only do the compile part.
# To prevent the CMake Warning: Manually-specified variables were not used by the project:
# we need to ignore it else
if(DEFINED DCMTK_NO_TRY_RUN)
  set(DCMTK_NO_TRY_RUN DDCMTK_NO_TRY_RUN CACHE INTERNAL "Disable compile try as part of config")
endif()


if(NOT DEFINED C_CHAR_UNSIGNED)
   message(STATUS "Checking signedness of char")
   DCMTK_TRY_COMPILE(C_CHAR_SIGNED_COMPILED "char is signed"
"// Fail compile for unsigned char.
int main()
{
  char *unused_array[((char)-1<0)?1:-1];
  return 0;
}")
   if(C_CHAR_SIGNED_COMPILED)
     message(STATUS "Checking signedness of char -- signed")
     set(C_CHAR_UNSIGNED 0 CACHE INTERNAL "Whether char is unsigned.")
   else()
     message(STATUS "Checking signedness of char -- unsigned")
     set(C_CHAR_UNSIGNED 1 CACHE INTERNAL "Whether char is unsigned.")
   endif()
 endif()

# Check for thread type
if(HAVE_WINDOWS_H)
  set(HAVE_INT_TYPE_PTHREAD_T 1)
else()
  DCMTK_TRY_COMPILE(HAVE_INT_TYPE_PTHREAD_T "pthread_t is an integer type"
        "// test to see if pthread_t is a pointer type or not

#include <pthread.h>

int main()
{
  pthread_t p;
  unsigned long l = p;
  return 0;
}")
  if(NOT HAVE_INT_TYPE_PTHREAD_T)
    set(HAVE_POINTER_TYPE_PTHREAD_T 1 CACHE INTERNAL "Set if pthread_t is a pointer type")
  else()
    set(HAVE_POINTER_TYPE_PTHREAD_T 0 CACHE INTERNAL "Set if pthread_t is a pointer type")
  endif()
endif()


# Check if ENAMETOOLONG is defined.
DCMTK_TRY_COMPILE(HAVE_ENAMETOOLONG "ENAMETOOLONG is defined"
    "#include <errno.h>

int main()
{
    int value = ENAMETOOLONG;
    return 0;
}")

# Check if strerror_r returns a char* is defined.
DCMTK_TRY_COMPILE(HAVE_INT_STRERROR_R "strerror_r returns an int"
    "#include <string.h>

int main()
{
    char *buf = 0;
    int i = strerror_r(0, buf, 100);
    return i;
}")
if(HAVE_INT_STRERROR_R)
  set(HAVE_CHARP_STRERROR_R 0 CACHE INTERNAL "Set if strerror_r() returns a char*")
else()
  set(HAVE_CHARP_STRERROR_R 1 CACHE INTERNAL "Set if strerror_r() returns a char*")
endif()

# Check if variable length arrays are supported.
DCMTK_TRY_COMPILE(HAVE_VLA "variable length arrays are supported"
    "int main()
{
    int n = 42;
    int foo[n];
    return 0;
}")

# do try compile to detect lfs and flags
function(DCMTK_LFS_TRY_COMPILE VAR FILE FLAGS DEFINITIONS)
  if(FLAGS OR DEFINITIONS)
    set(OPTIONS " with arguments: \"")
  else()
    set(OPTIONS)
  endif()
  if(DCMTK_TRY_COMPILE_REQUIRED_CMAKE_FLAGS OR FLAGS)
    set(CMAKE_FLAGS CMAKE_FLAGS ${DCMTK_TRY_COMPILE_REQUIRED_CMAKE_FLAGS})
    if(FLAGS)
      list(APPEND CMAKE_FLAGS "-DCMAKE_C_FLAGS:STRING=${FLAGS}")
      set(OPTIONS "${OPTIONS}${FLAGS}")
    endif()
  else()
    set(CMAKE_FLAGS)
  endif()
  if(DEFINITIONS)
    set(COMPILE_DEFINITIONS COMPILE_DEFINITIONS ${DEFINITIONS})
    if(FLAGS)
      set(OPTIONS "${OPTIONS} ")
    endif()
    set(OPTIONS "${OPTIONS}${DEFINITIONS}")
  else()
    set(COMPILE_DEFINITIONS)
  endif()
  if(FLAGS OR DEFINITIONS)
    set(OPTIONS "${OPTIONS}\"")
  endif()
  set(SOURCEFILE "${DCMTK_SOURCE_DIR}/config/tests/${FILE}")
  try_compile(RESULT
        "${CMAKE_BINARY_DIR}"
        "${SOURCEFILE}"
        ${CMAKE_FLAGS}
        ${COMPILE_DEFINITIONS}
        OUTPUT_VARIABLE OUTPUT
  )
  set("${VAR}" "${RESULT}" PARENT_SCOPE)
  if(RESULT)
    set(LOGFILE "CMakeOutput.log")
    set(LOG "succeeded")
  else()
    set(LOGFILE "CMakeError.log")
    set(LOG "failed")
  endif()
  file(TO_NATIVE_PATH "${SOURCEFILE}" SOURCEFILE)
  file(APPEND "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${LOGFILE}"
    "compiling \"${SOURCEFILE}\"${OPTIONS} ${LOG} with the following output:\n"
    "${OUTPUT}\n"
  )
endfunction()

function(DCMTK_CHECK_ENABLE_LFS)
  # normalize arguments
  if(DCMTK_ENABLE_LFS)
    # for cases insensitive comparison
    string(TOLOWER "${DCMTK_ENABLE_LFS}" DCMTK_ENABLE_LFS)
  endif()
  if(NOT DCMTK_ENABLE_LFS OR DCMTK_ENABLE_LFS MATCHES "^(on|true|yes|1)$")
    set(DCMTK_ENABLE_LFS "auto")
  elseif(DCMTK_ENABLE_LFS MATCHES "^(no|false|0)$")
    set(DCMTK_ENABLE_LFS "off")
  endif()
  # determine whether lfs64 is available in case it wasn't detected yet it may be used
  if(NOT DEFINED DCMTK_LFS64_AVAILABLE AND DCMTK_ENABLE_LFS MATCHES "^(lfs64|auto)$")
    set(DCMTK_LFS64_DEFINITIONS)
    set(MESSAGE_RESULT "no")
    set(MESSAGE "Checking whether explicit large file support (LFS64) is available")
    message(STATUS "${MESSAGE}")
    DCMTK_LFS_TRY_COMPILE(RESULT "lfs64.cc" "" "")
    if(RESULT)
      set(MESSAGE_RESULT "yes")
      set(DCMTK_ENABLE_LFS "lfs64")
      set(DCMTK_LFS64_DEFINITIONS "-D_LARGEFILE64_SOURCE")
      set(DCMTK_LFS64_DEFINITIONS "${DCMTK_LFS64_DEFINITIONS}" CACHE INTERNAL "which compiler definitions to set for enabling LFS64 support")
    endif()
    set(DCMTK_LFS64_AVAILABLE "${RESULT}" CACHE INTERNAL "whether LFS64 is available or not" FORCE)
    message(STATUS "${MESSAGE} -- ${MESSAGE_RESULT}")
  endif()
  # determine whether lfs is available in case it wasn't detected yet it may be used
  if(NOT DEFINED DCMTK_LFS_AVAILABLE AND DCMTK_ENABLE_LFS MATCHES "^(lfs|auto)$")
    set(DCMTK_LFS_FLAGS)
    set(DCMTK_LFS_DEFINITIONS)
    set(MESSAGE_RESULT "no")
    set(MESSAGE "Checking whether large file support (LFS) is available")
    message(STATUS "${MESSAGE}")
    # determine size of fpos_t (for the strange LFS implementation on Windows)
    set(CMAKE_EXTRA_INCLUDE_FILES)
    set(CMAKE_EXTRA_INCLUDE_FILES "stdio.h")
    CHECK_TYPE_SIZE("fpos_t" SIZEOF_FPOS_T)
    # assume sizeof off_t to be correct, will be removed if below tests fail
    set(SIZEOF_OFF_T 8)
    # try compile different combinations of compiler flags and definitions
    DCMTK_LFS_TRY_COMPILE(RESULT "lfs.c" "" "")
    if(NOT RESULT)
      set(DCMTK_LFS_FLAGS "-n32")
      DCMTK_LFS_TRY_COMPILE(RESULT "lfs.c" "-n32" "")
    endif()
    if(NOT RESULT)
      set(DCMTK_LFS_FLAGS "")
      set(DCMTK_LFS_DEFINITIONS "-D_FILE_OFFSET_BITS=64")
      DCMTK_LFS_TRY_COMPILE(RESULT "lfs.c" "" "-D_FILE_OFFSET_BITS=64")
    endif()
    if(NOT RESULT)
      set(DCMTK_LFS_FLAGS "-n32")
      set(DCMTK_LFS_DEFINITIONS "-D_FILE_OFFSET_BITS=64")
      DCMTK_LFS_TRY_COMPILE(RESULT "lfs.c" "-n32" "-D_FILE_OFFSET_BITS=64")
    endif()
    if(NOT RESULT)
      set(DCMTK_LFS_FLAGS "")
      set(DCMTK_LFS_DEFINITIONS "-D_LARGE_FILES=1")
      DCMTK_LFS_TRY_COMPILE(RESULT "lfs.c" "" "-D_LARGE_FILES=1")
    endif()
    if(NOT RESULT)
      set(DCMTK_LFS_FLAGS "-n32")
      set(DCMTK_LFS_DEFINITIONS "-D_LARGE_FILES=1")
      DCMTK_LFS_TRY_COMPILE(RESULT "lfs.c" "-n32" "-D_LARGE_FILES=1")
    endif()
    if(NOT RESULT)
      # remove flags and reset SIZEOF_OFF_T to indeterminate
      set(DCMTK_LFS_FLAGS)
      set(DCMTK_LFS_DEFINITIONS)
      set(SIZEOF_OFF_T)
      # detect strange LFS implementation that (at least) Windows provides
      # strange since sizeof(fpos_t) == 8 but sizeof(off_t) == 4!
      if(SIZEOF_FPOS_T EQUAL 8)
        set(RESULT TRUE)
      endif()
    endif()
    # format a nice result message
    if(RESULT)
      set(DCMTK_ENABLE_LFS "lfs")
      set(DCMTK_LFS_FLAGS "${DCMTK_LFS_FLAGS}" CACHE INTERNAL "which compiler flags to set for enabling LFS support")
      set(DCMTK_LFS_DEFINITIONS "${DCMTK_LFS_DEFINITIONS}" CACHE INTERNAL "which compiler definitions to set for enabling LFS support")
      set(MESSAGE_RESULT "yes")
      if(NOT DCMTK_LFS_FLAGS STREQUAL "" OR NOT DCMTK_LFS_DEFINITIONS STREQUAL "")
        set(MESSAGE_RESULT "${MESSAGE_RESULT}, with")
        if(NOT DCMTK_LFS_FLAGS STREQUAL "")
          set(MESSAGE_RESULT "${MESSAGE_RESULT} ${DCMTK_LFS_FLAGS}")
        endif()
        if(NOT DCMTK_LFS_DEFINITIONS STREQUAL "")
          set(MESSAGE_RESULT "${MESSAGE_RESULT} ${DCMTK_LFS_DEFINITIONS}")
        endif()
      endif()
    endif()
    set(DCMTK_LFS_AVAILABLE "${RESULT}" CACHE INTERNAL "whether LFS is available or not" FORCE)
    if(DEFINED SIZEOF_OFF_T)
      set(SIZEOF_OFF_T "${SIZEOF_OFF_T}" CACHE INTERNAL "")
    endif()
    message(STATUS "${MESSAGE} -- ${MESSAGE_RESULT}")
  endif()
  # auto-select LFS implementation in case this is not the first run and the above tests did not select it
  if(DCMTK_ENABLE_LFS STREQUAL "auto")
    if(DCMTK_LFS64_AVAILABLE)
      set(DCMTK_ENABLE_LFS "lfs64")
    elseif(DCMTK_LFS_AVAILABLE)
      set(DCMTK_ENABLE_LFS "lfs")
    else()
      set(DCMTK_ENABLE_LFS "off")
    endif()
  elseif(NOT DCMTK_ENABLE_LFS MATCHES "^(lfs|lfs64|off)$")
    # print a warning in case the given argument was not understood
    message(WARNING "unknown argument \"${DCMTK_ENABLE_LFS}\" for DCMTK_ENABLE_LFS, setting it to \"off\"")
    set(DCMTK_ENABLE_LFS "off")
  elseif(DCMTK_ENABLE_LFS STREQUAL "lfs64" AND NOT DCMTK_LFS64_AVAILABLE)
    # test if the explicitly chosen implementation is really available
    message(WARNING "LFS64 was enabled but LFS64 support is not available, focing DCMTK_ENABLE_LFS to \"off\"")
    set(DCMTK_ENABLE_LFS "off")
  elseif(DCMTK_ENABLE_LFS STREQUAL "lfs" AND NOT DCMTK_LFS_AVAILABLE)
    # test if the explicitly chosen implementation is really available
    message(WARNING "LFS was enabled but LFS support is not available, focing DCMTK_ENABLE_LFS to \"off\"")
    set(DCMTK_ENABLE_LFS "off")
  endif()
  # create a list of available LFS types for the CMake GUI
  set(AVAILABLE_LFS_TYPES)
  if(NOT DEFINED DCMTK_LFS64_AVAILABLE OR DCMTK_LFS64_AVAILABLE)
    list(APPEND AVAILABLE_LFS_TYPES "lfs64")
  endif()
  if(NOT DEFINED DCMTK_LFS_AVAILABLE OR DCMTK_LFS_AVAILABLE)
    list(APPEND AVAILABLE_LFS_TYPES "lfs")
  endif()
  # store the chosen value to the cache (potentially normalizing the given argument)
  set(DCMTK_ENABLE_LFS "${DCMTK_ENABLE_LFS}" CACHE STRING "whether to use lfs/lfs64 or not" FORCE)
  set_property(CACHE DCMTK_ENABLE_LFS  PROPERTY STRINGS "auto" ${AVAILABLE_LFS_TYPES} "off")
  # set values for osconfig.h and add compiler flags and definitions (if necessary)
  if(DCMTK_ENABLE_LFS STREQUAL "lfs64")
    # set the value for generating osconfig.h
    set(DCMTK_LFS_MODE "DCMTK_LFS64" CACHE INTERNAL "" FORCE)
    if(NOT DCMTK_LFS64_DEFINITIONS STREQUAL "")
      add_definitions(${DCMTK_LFS64_DEFINITIONS})
    endif()
    message(STATUS "Info: Building DCMTK with explicit large file support (LFS64)")
  elseif(DCMTK_ENABLE_LFS STREQUAL "lfs")
    # set the value for generating osconfig.h
    set(DCMTK_LFS_MODE "DCMTK_LFS" CACHE INTERNAL "" FORCE)
    if(NOT DCMTK_LFS_FLAGS STREQUAL "")
      set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${DCMTK_LFS_FLAGS}")
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${DCMTK_LFS_FLAGS}")
    endif()
    if(NOT DCMTK_LFS_DEFINITIONS STREQUAL "")
      add_definitions(${DCMTK_LFS_DEFINITIONS})
    endif()
    message(STATUS "Info: Building DCMTK with large file support (LFS)")
  else()
    set(DCMTK_ENABLE_LFS)
    message(STATUS "Info: Building DCMTK without large file support, files >4GB may be inaccessible!")
  endif()
endfunction()

DCMTK_CHECK_ENABLE_LFS()

# Check for alignment query / specifier support
DCMTK_TRY_COMPILE(HAVE_GNU_ALIGNOF "__alignof__ is supported"
    "int main()
{
    char c[__alignof__(int)];
    return 0;
}")

DCMTK_TRY_COMPILE(HAVE_MS_ALIGNOF "__alignof is supported"
    "int main()
{
    char c[__alignof(int)];
    return 0;
}")

DCMTK_TRY_COMPILE(HAVE_ATTRIBUTE_ALIGNED "__attribute__((aligned)) is supported"
    "int main()
{
    __attribute__((aligned(4))) char c[16];
    return 0;
}")

DCMTK_TRY_COMPILE(ATTRIBUTE_ALIGNED_SUPPORTS_TEMPLATES "__attribute__((aligned)) supports templates"
    "template<typename T>
struct test { typedef T type __attribute__((aligned(4))); };
int main()
{
    test<char>::type i;
    return 0;
}")

DCMTK_TRY_COMPILE(HAVE_DECLSPEC_ALIGN "__declspec(align) is supported"
    "int main()
{
    __declspec(align(4)) char c[16];
    return 0;
}")

DCMTK_TRY_COMPILE(HAVE_DEFAULT_CONSTRUCTOR_DETECTION_VIA_SFINAE "the compiler supports default constructor detection via SFINAE"
    "struct no_type {};
struct yes_type {double d;};
template<unsigned>
struct consume{};
template<typename X>
static yes_type sfinae(consume<sizeof *new X>*);
template<typename X>
static no_type sfinae(...);
struct test { test( int ); };
template<int I>
struct enable {};
template<>
struct enable<0> { enum { result = 0 }; };
int main()
{
    return enable<sizeof(sfinae<test>(0)) == sizeof(yes_type)>::result;
}")

DCMTK_TRY_COMPILE(HAVE_STATIC_ASSERT "the compiler supports static_assert"
    "#include <cassert>
int main()
{
    static_assert(true, \"good\");
    return 0;
}")

DCMTK_TRY_COMPILE(HAVE_CXX14_DEPRECATED_ATTRIBUTE "the compiler supports [[deprecated]]" "[[deprecated]] int main(){return 0;}")
DCMTK_TRY_COMPILE(HAVE_CXX14_DEPRECATED_ATTRIBUTE_MSG "the compiler supports [[deprecated(\"message\")]]" "[[deprecated(\"message\")]] int main(){return 0;}")
DCMTK_TRY_COMPILE(HAVE_ATTRIBUTE_DEPRECATED "the compiler supports __attribute__((deprecated))" "__attribute__((deprecated)) int main(){return 0;}")
DCMTK_TRY_COMPILE(HAVE_ATTRIBUTE_DEPRECATED_MSG "the compiler supports __attribute__((deprecated(\"message\")))" "__attribute__((deprecated(\"message\"))) int main(){return 0;}")
DCMTK_TRY_COMPILE(HAVE_DECLSPEC_DEPRECATED "the compiler supports __declspec(deprecated)" "__declspec(deprecated) int main(){return 0;}")
DCMTK_TRY_COMPILE(HAVE_DECLSPEC_DEPRECATED_MSG "the compiler supports __declspec(deprecated(\"message\"))" "__declspec(deprecated(\"message\")) int main(){return 0;}")

function(DCMTK_CHECK_ITERATOR_CATEGORY CATEGORY)
    if(HAVE_ITERATOR_HEADER)
        string(TOUPPER "${CATEGORY}" CAT)
        DCMTK_TRY_COMPILE(HAVE_${CAT}_ITERATOR_CATEGORY "the iterator category ${CATEGORY} is declared"
            "#include <iterator>
int main()
{
    typedef std::${CATEGORY}_iterator_tag category;
    return 0;
}")
    endif()
endfunction()

DCMTK_CHECK_ITERATOR_CATEGORY(contiguous)

function(ANALYZE_ICONV_FLAGS)
    if(DCMTK_WITH_ICONV OR DCMTK_WITH_STDLIBC_ICONV)
        set(TEXT "Detecting fixed iconv conversion flags")
        message(STATUS "${TEXT}")
        set(EXTRA_ARGS)
        if(NOT DCMTK_WITH_STDLIBC_ICONV)
            list(APPEND EXTRA_ARGS
                CMAKE_FLAGS "-DINCLUDE_DIRECTORIES=${LIBICONV_INCDIR}"
                LINK_LIBRARIES ${LIBICONV_LIBS}
            )
        endif()
        if(LIBICONV_SECOND_ARGUMENT_CONST)
            list(APPEND EXTRA_ARGS
                COMPILE_DEFINITIONS "-DLIBICONV_SECOND_ARGUMENT_CONST=${LIBICONV_SECOND_ARGUMENT_CONST}"
            )
        endif()
        if(NOT DEFINED DCMTK_NO_TRY_RUN)
          DCMTK_TRY_RUN(RUN_RESULT COMPILE_RESULT
              "${CMAKE_BINARY_DIR}/CMakeTmp/Iconv"
              "${DCMTK_SOURCE_DIR}/config/tests/iconv.cc"
              ${EXTRA_ARGS}
              COMPILE_OUTPUT_VARIABLE CERR
              RUN_OUTPUT_VARIABLE OUTPUT
          )
          if(COMPILE_RESULT)
              set(DCMTK_ICONV_FLAGS_ANALYZED TRUE CACHE INTERNAL "")
              if(RUN_RESULT EQUAL 0)
                  message(STATUS "${TEXT} - ${OUTPUT}")
                  set(DCMTK_FIXED_ICONV_CONVERSION_FLAGS "${OUTPUT}" CACHE INTERNAL "")
              else()
                  message(STATUS "${TEXT} - unknown")
              endif()
          else()
              message(FATAL_ERROR "${CERR}")
          endif()
        else()
          if(NOT DEFINED DCMTK_ICONV_FLAGS_ANALYZED)
            message(FATAL_ERROR "When using DCMTK_NO_TRY_RUN, set DCMTK_ICONV_FLAGS_ANALYZED")
          endif()
          if(NOT DEFINED DCMTK_FIXED_ICONV_CONVERSION_FLAGS)
            message(FATAL_ERROR "When using DCMTK_NO_TRY_RUN, set DCMTK_FIXED_ICONV_CONVERSION_FLAGS")
          endif()
        endif()
    endif()
endfunction()

if(NOT DCMTK_ICONV_FLAGS_ANALYZED)
    analyze_iconv_flags()
endif()

function(ANALYZE_STDLIBC_ICONV_DEFAULT_ENCODING)
    if(DCMTK_WITH_STDLIBC_ICONV)
        set(TEXT "Checking whether iconv_open() accepts \"\" as an argument")
        message(STATUS "${TEXT}")
        set(EXTRA_ARGS)
        if(NOT DEFINED DCMTK_NO_TRY_RUN)
          DCMTK_TRY_RUN(RUN_RESULT COMPILE_RESULT
              "${CMAKE_BINARY_DIR}/CMakeTmp/lciconv"
              "${DCMTK_SOURCE_DIR}/config/tests/lciconv.cc"
              COMPILE_OUTPUT_VARIABLE CERR
          )
          if(COMPILE_RESULT)
              if(RUN_RESULT EQUAL 0)
                  message(STATUS "${TEXT} - yes")
                  set(DCMTK_STDLIBC_ICONV_HAS_DEFAULT_ENCODING 1 CACHE INTERNAL "")
              else()
                  message(STATUS "${TEXT} - no")
                  set(DCMTK_STDLIBC_ICONV_HAS_DEFAULT_ENCODING CACHE INTERNAL "")
              endif()
          else()
              message(FATAL_ERROR "${CERR}")
          endif()
        else()
          if(NOT DEFINED DCMTK_STDLIBC_ICONV_HAS_DEFAULT_ENCODING)
            message(FATAL_ERROR "When using DCMTK_NO_TRY_RUN, set DCMTK_STDLIBC_ICONV_HAS_DEFAULT_ENCODING")
          endif()
        endif()
    endif()
endfunction()

if(NOT DEFINED DCMTK_STDLIBC_ICONV_HAS_DEFAULT_ENCODING)
    analyze_stdlibc_iconv_default_encoding()
endif()

if(HAVE_PASSWD_GECOS AND NOT DEFINED PASSWD_GECOS_IS_DEFINE_TO_PASSWD)
    DCMTK_TRY_COMPILE(PASSWD_GECOS_IS_DEFINE_TO_PASSWD "pw_gecos is #defined to pw_passwd"
        "#include <pwd.h>
int main()
{
    struct S { int pw_passwd; };
    &S::pw_gecos;
    return 0;
}")
    if(PASSWD_GECOS_IS_DEFINE_TO_PASSWD)
        set(HAVE_PASSWD_GECOS 0 CACHE INTERNAL "Have symbol &passwd::pw_gecos")
    endif()
endif()

# Check whether the compiler supports the given C++ standard version (11, 14, ...)
function(DCMTK_CHECK_CXX_STANDARD STANDARD)
  set(RESULT 0)
  if(DEFINED HAVE_CXX${STANDARD}_TEST_RESULT)
    if(HAVE_CXX${STANDARD}_TEST_RESULT)
      set(RESULT 1)
    endif()
  else()
    set(MESSAGE "Checking whether the compiler supports C++${STANDARD}")
    message(STATUS "${MESSAGE}")
    # Here we need to tell try_compile() to set the related CXX standard macro for VS.
    # try_compile() also now support forwarding CMAKE_CXX_STANDARD to the compiler by setting "CXX_STANDARD <version>"
    # but for some reason it does not seem to work. Thus we meanwhile set the macro manually.
    try_compile(COMPILE_RESULT "${CMAKE_BINARY_DIR}" "${DCMTK_SOURCE_DIR}/config/tests/cxx${STANDARD}.cc" COMPILE_DEFINITIONS ${FORCE_MSVC_CPLUSPLUS_MACRO})
    set(HAVE_CXX${STANDARD}_TEST_RESULT "${COMPILE_RESULT}" CACHE INTERNAL "Caches the configuration test result for C++${STANDARD} support.")
    if(COMPILE_RESULT)
      set(RESULT 1)
      message(STATUS "${MESSAGE} -- yes")
    else()
      message(STATUS "${MESSAGE} -- no")
    endif()
  endif()
  set("ENABLE_CXX${STANDARD}" "${RESULT}" PARENT_SCOPE)
endfunction()


# Loop through all C++ standard versions (11, 14, ...) up to requested CMAKE_CXX_STANDARD
# whether the features of that version are actually available.
# If yes, then various HAVE_CXX${STANDARD} variables are set to 1 for that version and
# all versions below. osconfig.h will then contain C++ defines (with the same names)
# used by DCMTK to enable/disable C++ version-related language features.
function(DCMTK_TEST_LATEST_CXX_STANDARD)
  get_property(MODERN_CXX_STANDARDS GLOBAL PROPERTY DCMTK_MODERN_CXX_STANDARDS)
  # Define/reset all HAVE_CXX${STANDARD} to 0
  foreach(STANDARD ${MODERN_CXX_STANDARDS})
    set(ENABLE_CXX${STANDARD} 0)
  endforeach()
  # Get list of modern C++ standards (>= 11) created in dcmtkPrepare.cmake
  get_property(MODERN_CXX_STANDARD GLOBAL PROPERTY DCMTK_MODERN_CXX_STANDARD)
  # If we want to use C++11 or later, check if the compiler supports it
  if(MODERN_CXX_STANDARD)
    # Highest C++ standard version to tbe checked (all versions betwen C++11 and highest in MODERN_CXX_STANDARDS)
    dcmtk_upper_bound(MODERN_CXX_STANDARDS "${CMAKE_CXX_STANDARD}" N)
    math(EXPR N "${N}-1")
    # Loop over C++ standards (11, 14, ...) up to highest to be checked
    foreach(I RANGE ${N})
      list(GET MODERN_CXX_STANDARDS ${I} STANDARD)
      # Check whether given C++ standard is supported by the compiler
      dcmtk_check_cxx_standard("${STANDARD}")
      # If not, we are done (reached the highest supported C++ standard)
      if(NOT ENABLE_CXX${STANDARD})
        break()
      endif()
    endforeach()
  endif()

  # Print message for each C++ standard version >11 whether it's supported or not
  foreach(STANDARD ${MODERN_CXX_STANDARDS})
    set(HAVE_CXX${STANDARD} "${ENABLE_CXX${STANDARD}}" CACHE INTERNAL "Set to 1 if the compiler supports C++${STANDARD} and it should be enabled.")
    if(HAVE_CXX${STANDARD})
      message(STATUS "Info: C++${STANDARD} features enabled")
    else()
      message(STATUS "Info: C++${STANDARD} features disabled")
    endif()

  endforeach()
endfunction()

function(DCMTK_ENABLE_STL98_FEATURE NAME)
  string(TOUPPER "${NAME}" FEATURE)
  if(DCMTK_ENABLE_STL_${FEATURE} STREQUAL "INFERRED")
    set(DCMTK_ENABLE_STL_${FEATURE} ${DCMTK_ENABLE_STL})
  endif()
  if(DCMTK_ENABLE_STL_${FEATURE})
    set(RESULT 1)
    set(TEXT_RESULT "enabled")
  else()
    set(RESULT 0)
    set(TEXT_RESULT "disabled")
  endif()
  set(HAVE_STL_${FEATURE} ${RESULT} CACHE INTERNAL "Set to 1 if the compiler/OS provides a working STL ${NAME} implementation.")
  message(STATUS "Info: STL ${NAME} support ${TEXT_RESULT}")
endfunction()

function(DCMTK_ENABLE_STL11_FEATURE NAME)
  string(TOUPPER "${NAME}" FEATURE)
  string(TOUPPER "HAVE_${NAME}" HEADER_PRESENT)
  if(DCMTK_ENABLE_STL_${FEATURE} STREQUAL "INFERRED")
    set(DCMTK_ENABLE_STL_${FEATURE} ${DCMTK_ENABLE_STL})
  endif()
  if((DCMTK_ENABLE_STL_${FEATURE}) AND ${HEADER_PRESENT})
    set(RESULT 1)
    set(TEXT_RESULT "enabled")
  else()
    set(RESULT 0)
    set(TEXT_RESULT "disabled")
  endif()
  set(HAVE_STL_${FEATURE} ${RESULT} CACHE INTERNAL "Set to 1 if the compiler/OS provides a working STL ${NAME} implementation.")
  message(STATUS "Info: STL ${NAME} support ${TEXT_RESULT}")
endfunction()

# This variable is used to force VS 2017 and above to explicitly
# state the C++ standard version used in the __cplusplus macro
# during compilation. This macro is checked when features from C++11
# and about to be enabled.
# VS Versions < 2017 do not support this switch.
# See also https://learn.microsoft.com/de-de/cpp/build/reference/zc-cplusplus
set(FORCE_MSVC_CPLUSPLUS_MACRO "")
if(MSVC)
  if(NOT (MSVC_VERSION LESS 1910)) # VS 2017 and above
    set(FORCE_MSVC_CPLUSPLUS_MACRO "/Zc:__cplusplus")
  endif()
endif()

# Check which modern C++ standards can be enabled
DCMTK_TEST_LATEST_CXX_STANDARD()
DCMTK_ENABLE_STL98_FEATURE("algorithm")
DCMTK_ENABLE_STL98_FEATURE("list")
DCMTK_ENABLE_STL98_FEATURE("map")
DCMTK_ENABLE_STL98_FEATURE("memory")
DCMTK_ENABLE_STL98_FEATURE("stack")
DCMTK_ENABLE_STL98_FEATURE("string")
DCMTK_ENABLE_STL98_FEATURE("vector")

DCMTK_ENABLE_STL11_FEATURE("type_traits")
DCMTK_ENABLE_STL11_FEATURE("tuple")
DCMTK_ENABLE_STL11_FEATURE("system_error")
DCMTK_ENABLE_STL11_FEATURE("atomic")

# if at least one modern C++ standard should be supported,
# enforce setting of __cplusplus macro in VS 2017 and above
if(MSVC)
  get_property(MODERN_CXX_STANDARDS GLOBAL PROPERTY DCMTK_MODERN_CXX_STANDARDS)
  foreach(STANDARD ${MODERN_CXX_STANDARDS})
    if(HAVE_CXX${STANDARD})
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${FORCE_MSVC_CPLUSPLUS_MACRO}")
      break()
    endif()
  endforeach()
endif()

if(NOT HAVE_CXX11 AND NOT DCMTK_PERMIT_CXX98)
  # Since the situation where the user has explicitly requested CMAKE_CXX_STANDARD=98
  # has already been handled in dcmtkPrepare.cmake, we are apparently using a compiler
  # that uses C++98 by default, and the user has not requested anything specific.
  message(FATAL_ERROR "DCMTK will require C++11 or later in the future (which is apparently not supported by this compiler). Use cmake option -DDCMTK_PERMIT_CXX98=ON to override this error (for now).")
endif()

if(CMAKE_CROSSCOMPILING)
  set(DCMTK_CROSS_COMPILING ${CMAKE_CROSSCOMPILING})
endif()
