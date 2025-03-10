## OBSOLETE

def _module_profiles_impl(ctx):
    items = {}
    for item in ctx.attr.repos:
        # print("ITEM: %s" % item)

        wsname = item.label.workspace_name
        # print("item.label.workspace_name: %s" % wsname)

        tildes = wsname.count("~")
        # print("tilde ct: %s" % tildes)

        ## https://bazel.build/external/extension#repository_names_and_visibility
        # print("splitting %s" % wsname)

        segs = wsname.split("~")
        root_repo = segs[0]
        # print("ROOT %s" % root_repo)

        if root_repo == "_main":
            root_repo = "."
            if tildes > 0:
                # should be a pair, extension~repo
                ext_repo = segs[2]
            else:
                ext_repo  = None
        else:

            version   = segs[1]
            if tildes > 1:
                # 2nd seg is repo version (or "override")
                # 3rd is extension name
                # 4th is extension repo
                extension = segs[2]
                ext_repo  = segs[3]
            else:
                extension = None
                ext_repo  = None

        # print("REPO %s" % root_repo)
        # print("VERSION %s" % version)
        # print("EXTENSION %s" % extension)
        # print("EXT REPO %s" % ext_repo)

        if ext_repo:
            items["@" + ext_repo] = item.label.workspace_root
        else:
            items["@" + root_repo] = item.label.workspace_root

    items["@"] = ctx.attr.this
    items["MODULE_NAME"] = ctx.attr.module_name
    items["MODULE_VERSION"] = ctx.attr.module_version

    # print("THIS: %s" % ctx.attr.this)
    # print("MAKE VARS: %s" % items)

    return [platform_common.TemplateVariableInfo(items)]

################
_module_profiles = rule(
    implementation = _module_profiles_impl,
    attrs = {"repos": attr.label_list(),
             "this": attr.string(),
             "module_name": attr.string(),
             "module_version": attr.string()
             }
)

################################################################
## macro (public)
def module_profiles(name, repos, visibility=None):
    if native.repository_name() == "@":
       _this = "."
    else:
        _this = "external/{}".format(
            native.repository_name()[1:])

    _module_profiles(name = name,
                     repos = repos,
                    this = _this,
                    module_name = native.module_name().upper(),
                    module_version = native.module_version(),
                    visibility = ["//visibility:public"])
