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
        # GCC:
        "-Werror",
    ],
    "//conditions:default": ["-std=c11"],
})

BASE_LINKOPTS = select({
    "@platforms//os:linux": ["-rdynamic", "-ldl"],
    "@platforms//os:macos": [],
    "//conditions:default": []
})

BASE_LOCAL_DEFINES = ["DEBUG_$(COMPILATION_MODE)"]

def MODULE_VERSION():
    return "'-D{}_VERSION=\"{}\"'".format(
        native.module_name().upper(),
        native.module_version()
    )


    # select({
    #     "//bzl/host:macos": []
    #     "//bzl/host:linux": ["-D_POSIX_C_SOURCE=200809L", ## strndup etc.
    #                          "-D_DEFAULT_SOURCE", ## DT_* from dirent.h
    #                          "_XOPEN_SOURCE=500"], # strdup

    #     "//conditions:default": []
    # })


# BASE_DEFINES = select({
#     "@obazl_tools_cc//profile:dev?": ["DEVBUILD"],
#     "//conditions:default": []
# }) + select({
#     "@obazl_tools_cc//trace:trace?": ["TRACING"],
#     "//conditions:default": []
# })

