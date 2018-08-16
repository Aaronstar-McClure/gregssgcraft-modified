#------------------------------------------------------------------------------
#
#   Upload a mod to curseforge
#
#   Usage: cfupload projectid modversion mcversion jarfile readmefile
#
#------------------------------------------------------------------------------

import json, os, requests, sys
from collections import defaultdict
from BeautifulSoup import BeautifulSoup

import warnings
warnings.simplefilter("ignore")

site = "https://minecraft.curseforge.com"
token = open(os.path.expanduser("~/secrets/minecraft-curseforge-api-key.txt")).readline().strip()
print "Token =", repr(token)
token_header = {"X-Api-Token": token}
dry_run = False

def extract_changelog(mcversion, modversion, readmefile):
    soup = BeautifulSoup(open(readmefile).read())
    changelog = soup.find(id = "changelog")
    if not changelog:
        raise EnvironmentError("Cannot find element with id 'changelog' in %s" % readmefile)
    target = "Version %s" % modversion
    for dt in changelog.findAll("dt"):
        if dt.string == target:
            #print dt
            dd = dt.findNextSibling("dd")
            if not dd:
                raise EnvironmentError("Cannot find <dd> for '%s'" % target)
            items = []
            strings = []
            def flush_strings():
                if strings:
                    items.append(" ".join(strings))
                    del strings[:]
            while dd and dd.name == "dd":
                for elem in dd.contents:
                    if isinstance(elem, unicode):
                        #print "Changelog string:", repr(elem)
                        strings.extend(elem.split())
                    else:
                        #print "Changelog elem:", elem
                        flush_strings()
                dd = dd.findNextSibling(["dd", "dt"])
            flush_strings()
            lines = []
            for elem in items:
                if "0" <= elem[:1] <= "9" and ":" in elem:
                    prefix, _, line = elem.partition(":")
                    tags = [tag.strip() for tag in prefix.split(",")]
                    if mcversion in tags:
                        lines.append(line.strip())
                else:
                    lines.append(elem)
            return "\n".join(lines).strip()
    raise EnvironmentError("Cannot find '%s' in changelog" % target)

def get_game_versions():
    url = "%s/api/game/versions" % (site,)
    resp = requests.get(url, headers = token_header)
    try:
        versions = resp.json()
    except ValueError:
        raise EnvironmentError("No json in game versions response")
    versions_by_name = {}
    for version in versions:
        versions_by_name[version["name"]] = version
    return versions_by_name    

def get_version_id(versions, version_name):
    info = versions.get(version_name)
    if not info:
        raise EnvironmentError("Minecraft version '%s' not found" % version_name)
    return info["id"]

def upload(projectid, changelog, versions, jarfile):
    metadata = json.dumps({
        "changelogType": "text",
        "changelog": changelog,
        #"displayName": os.path.split(jarfile)[1],
        "gameVersions": versions,
        "releaseType": "release",
    })
    #print "metadata =", repr(metadata)
    url = "%s/api/projects/%s/upload-file" % (site, projectid)
    #url = "http://httpbin.org/post"
    #url = "http://requestb.in/1ek9jlk1"
    if not dry_run:
        print "Posting to:", url
        resp = requests.post(url,
            headers = token_header,
            data = {"metadata": metadata},
            files = {"file": open(jarfile, "rb")},
        )
        try:
            result = resp.json()
        except ValueError:
            raise EnvironmentError("No json in response")
        if "id" in result:
            print "Upload successful, file id =", result["id"]
        else:
            raise EnvironmentError("Upload failed: %s" % (result,))

def main():
    args = sys.argv[1:]
    if "-n" in args:
        global dry_run
        dry_run = True
        args.remove("-n")
    projectid, modversion, mcversion, jarfile, readmefile = args
    changelog = extract_changelog(mcversion, modversion, readmefile)
    print "--- Changelog ---"
    print changelog
    print "-----------------"
    versions = get_game_versions()
    #print "Versions =", versions
    mc_version_id = get_version_id(versions, mcversion)
    java_version_id = get_version_id(versions, "Java 7")
    print "File =", jarfile
    print "MC Version ID =", mc_version_id
    print "Java Version ID =", java_version_id
    upload(projectid, changelog, [mc_version_id, java_version_id], jarfile)

try:
    main()
except EnvironmentError, e:
    print >>sys.stderr, e
    sys.exit(1)
