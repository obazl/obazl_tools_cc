def define_module_version():
    return ["'{}_VERSION=\"{}\"'".format(
        native.module_name().upper(),
        native.module_version()
    )]

BASE_COPTS = [
    "-x", "c",
    "-Wall",
    "-Wextra",
    "-Werror",
    "-Wfatal-errors",
] + select({
    "@platforms//os:macos": [
        "-std=c11",
        "-Werror=pedantic",
        "-Wpedantic",
        "-pedantic-errors",
    ],
    "@platforms//os:linux": [
        "-std=gnu11",
        "-fPIC",
    ],
    "//conditions:default": ["-std=c11"],
})

BASE_LINKOPTS = select({
    "@platforms//os:linux": ["-rdynamic", "-ldl"],
    "@platforms//os:macos": [],
    "//conditions:default": []
})

## we want this to percolate upwards
# PROFILE = "PROFILE_$(COMPILATION_MODE)"

BASE_DSO_EXT = select({
    "//config/host/build:linux?": ["DSO_EXT=\\\".so\\\""],
    "//config/host/build:macos?": ["DSO_EXT=\\\".dylib\\\""],
    "//conditions:default":   ["DSO_EXT=\\\".so\\\""]
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

