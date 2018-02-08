#!/usr/local/bin/python
#--------------------------------------------------------------------------
#
#   Minecraft Launcher - MC1.8 version
#
#--------------------------------------------------------------------------

import os, sys

appsupport_dir = "/Users/greg/Library/Application Support/minecraft"
default_username = "gcewing"

# Pre 1.6
mcdirect_app = "/Local/Games/Minecraft/Minecraft-Direct.app"
mc_exe = os.path.join(mcdirect_app, "Contents/MacOS/JavaApplicationStub")
mc_launch_args = [mc_exe]

def mcpath(*args):
    return os.path.join(appsupport_dir, *args)

#mc_assets = mcpath("assets") # pre 1.7
#mc_assets = mcpath("assets/virtual/legacy")
mc_assets_root = mcpath("assets")

overrides = {}

def subdir_of(path):
    names = [name for name in os.listdir(path) if not name.startswith(".")]
    print "Versions in profile:", names
    if len(names) == 1:
        return names[0]

def read_json(path):
    return eval(open(path).read().replace("true", "True").replace("false", "False"))

def read_json_for_version(version):
    result = read_json(mcpath("versions", version, version + ".json"))
    result['__version__'] = version
    return result

def read_json_for_version_with_inheritance(version):
    result = read_json_for_version(version)
    parent_version = result.get('inheritsFrom')
    if parent_version:
        result['__parent__'] = read_json_for_version_with_inheritance(parent_version)
    return result

def get_with_inheritance(json, name):
    if name in json:
        return json[name]
    else:
        parent = json.get('__parent__')
        if parent:
            return get_with_inheritance(parent, name)
        else:
            raise KeyError("%s not found in version json" % name)

def find_jars(dir):
    result = []
    for (path, dirs, names) in os.walk(dir):
        for name in dirs + names:
            if name.endswith(".jar"):
                result.append(os.path.join(path, name))
    return result

def library_passes_rules(lib):
    rules = lib.get('rules')
    if not rules:
        return True
    default_rule = None
    for rule in rules:
        os = rule.get('os')
        if os:
            if os['name'] == "osx":
                return rule['action'] == "allow"
        else:
            default_rule = rule
    if default_rule:
        return default_rule['action'] == "allow"

def find_libraries(version_json, dir):
    parent_json = version_json.get('__parent__')
    if parent_json:
        result = find_libraries(parent_json, dir)
    else:
        result = {}
    print "mclaunch: Finding libraries in version json for", version_json['__version__']
    for lib in version_json['libraries']:
        if 'natives' not in lib:
            if library_passes_rules(lib):
                name = lib['name']
                pkg, tag, ver = name.split(":")
                relpath = "{0}/{1}/{2}/{1}-{2}.jar".format(pkg.replace(".", "/"), tag, ver)
                jar = os.path.join(dir, relpath)
                print "mclaunch: Using library %s = %s" % (name, jar)
                result[name] =jar
    return result

def old_launch_args(user):
    jars = find_jars(mcpath("bin"))
    return ["java", "-Xincgc", "-Xms1024M", "-Xmx1024M",
            "-cp", ":".join(jars),
            "-Djava.library.path=" + mcpath("bin/natives"),
            "net.minecraft.client.Minecraft",
            user]

def add_profile_args(args, **vars):
    version = vars["version_name"]
    json = read_json_for_version_with_inheritance(version)
    args.append(json["mainClass"])
    ma = iter(json["minecraftArguments"].split())
    for word in ma:
        if word == "--session":
            ma.next()
        else:
            if word.startswith("$"):
                word = vars.get(word[2:-1], "unknown")
            args.append(word)
    return args

def new_launch_args(launcher_profile_name, user, uuid):
    json = read_json(mcpath("launcher_profiles.json"))
    if not launcher_profile_name:
        launcher_profile_name = json.get("selectedProfile")
    if not launcher_profile_name:
        raise EnvironmentError("No profile selected in launcher")
    pf = json["profiles"].get(launcher_profile_name)
    if not pf:
        raise EnvironmentError("Profile not found: %s" % launcher_profile_name)
    version = pf.get("lastVersionId")
    if not version:
        raise EnvironmentError("Profile does not specify version: %s" % launcher_profile_name)
    game_dir = overrides.get("gameDir") or pf.get("gameDir", appsupport_dir)
    natives = mcpath("natives")
    version_json = read_json_for_version_with_inheritance(version)
    jars = find_libraries(version_json, mcpath("libraries")).values()
    base_version = version_json.get('jar', version)
    jars.append(mcpath("versions", base_version, base_version + ".jar"))
    args = ["java",
        "-Xdock:name=Minecraft",
        "-Xmx1G",
        "-XX:MaxPermSize=128m",
        "-Djava.library.path=" + natives,
        "-cp", ":".join(jars),
    ]
    add_profile_args(args,
        auth_player_name = user,
        auth_uuid = uuid,
        version_name = version, 
        game_directory = game_dir,
        assets_root = mc_assets_root,
        assets_index_name = get_with_inheritance(version_json, 'assets'), #version_json.get('assets', 'unknown_assets_index_name'),
        user_type = "legacy",
        user_properties = "{}")
    return args

def launch_args(launcher_profile_name, user, uuid):
    user = user or default_username
    if not os.path.exists(mc_assets_root):
        print "mclaunch: Using old launch method"
        return old_launch_args(user)
    else:
        print "mclaunch: Using new launch method"
        return new_launch_args(launcher_profile_name, user, uuid)

def switch_to_profile(profile_path):
    if profile_path != appsupport_dir:
        try:
            os.unlink(appsupport_dir)
        except EnvironmentError:
            pass
        os.symlink(profile_path, appsupport_dir)

def shescape(arg):
    return arg.replace(" ", r"\ ")

def spawn(launcher_profile_name = None, user = None, uuid = None):
    print "mclaunch.spawn:", repr(launcher_profile_name), repr(user) ###
    args = launch_args(launcher_profile_name, user, uuid)
    print "Spawning:", args ###
    os.spawnvp(os.P_NOWAIT, args[0], args)

def execute(launcher_profile_name = None, user = None, uuid = None):
    args = launch_args(launcher_profile_name, user, uuid)
    print "mclaunch: Executing:", " ".join(map(shescape, args)) ###
    os.execvp(args[0], args)

def fatal(mess):
    sys.stderr.write("%s\n" % mess)
    sys.exit(1)

def main():
    args = sys.argv[1:]
    def poparg(i = 0):
        if args:
            return args.pop(i)
    def popopt(s):
        try:
            i = args.index(s)
        except ValueError:
            return None
        del args[i]
        return poparg(i)
    launcher_profile_name = popopt("-p")
    user = popopt("-u")
    uuid = popopt("--uuid")
    overrides["gameDir"] = popopt("--gameDir")
    profile_dir = poparg() or appsupport_dir
    try:
        switch_to_profile(profile_dir)
        execute(launcher_profile_name, user, uuid)
    except EnvironmentError as e:
        fatal(str(e))

if __name__ == "__main__":
    main()
