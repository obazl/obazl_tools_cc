def define_module_version():
    return ["'{}_VERSION=\"{}\"'".format(
        native.module_name().upper(),
        native.module_version()
    )]

BASE_OPTS = [
    "-Wall",
    "-Wextra",
    "-Werror",
    "-Wfatal-errors",
] + select({
    "@platforms//os:macos": [
        "-Werror=pedantic",
        "-Wpedantic",
        "-pedantic-errors",
    ],
    # WARNING: assuming gcc?
    "@platforms//os:linux": [
        # "-std=gnu11",  ???
        # "-fPIC", ## bazel already provides this?
        # "-Wl,--no-undefined",
    ],
    "//conditions:default": []
})

## WARNING: -std=c11 on linux gcc requires feature test
## macros for some lib apis (strdup, macros in <dlfcn.h>, etc.)
## e.g. _POSIX_C_SOURCE >= 200809L or -D_GNU_SOURCE
## using -std=gnu11 does this automatically(?)
BASE_COPTS = BASE_OPTS + ["-x", "c", "-std=c11"]
# + select({
#     # "@platforms//os:linux": ["-std=gnu11"], # gcc extensions
#     "//conditions:default": ["-std=c11"]
# })

BASE_CXXOPTS = BASE_OPTS + ["-x", "c++", "-std=c++17"]
# + select({
#     # "@platforms//os:linux": ["-std=gnu++17"], # gcc default
#     "//conditions:default": ["-std=c++17"]
# })

DYNLINK_OPTS = select({
    "@obazl_tools_cc//profile:linux_opt": ["-rdynamic", "-ldl"],
    "@obazl_tools_cc//profile:macos_opt": ["-Wl,-export_dynamic"], # "-ldl"
    # "@platforms//os:linux": ["-rdynamic", "-ldl"],
    # "@platforms//os:macos": ["-Wl,-export_dynamic"], # "-ldl"
    "//conditions:default": []
})

## we want this to percolate upwards
# PROFILE = "PROFILE_$(COMPILATION_MODE)"

DSO_EXT = select({
    "@platforms//os:linux": ["DSO_EXT=\\\".so\\\""],
    "@platforms//os:macos": ["DSO_EXT=\\\".dylib\\\""],
    "//conditions:default":   ["DSO_EXT=\\\".so\\\""]
})

STRDUP_DEFINE =select({
    # strdup, strndup since glibc 2.10
    "@platforms//os:linux": ["_POSIX_C_SOURCE=200809L"],
    # "_XOPEN_SOURCE=500"],
    "//conditions:default":   []
})

DIRENT_DEFINE =select({
    "@platforms//os:linux": ["_DEFAULT_SOURCE"],
    "//conditions:default":   []
})

DLSYM_DEFINE =select({
    "@platforms//os:linux": ["_GNU_SOURCE"],
    "//conditions:default":   []
})

# defines =
# select({
#     "//config/host/build:linux?": [
#         # "_XOPEN_SOURCE=500", # strdup
#         "_POSIX_C_SOURCE=200809L", # strdup, strndup since glibc 2.10
#         "_DEFAULT_SOURCE",    # dirent macros
#         "_GNU_SOURCE"         # dlsym RTLD macros
#     ],
#     "//conditions:default":   []
# })

