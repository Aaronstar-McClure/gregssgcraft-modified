#----------------------------------------------------------------------------------------
#
#   genreadme - Generate README.html file from template and version database
#
#   Usage: genreadme mod_name
#          genreadme mod_name source_file dest_file
#
#----------------------------------------------------------------------------------------

import os, sys, sqlite3, textwrap
from jinja2 import Template
from collections import namedtuple
from BeautifulSoup import BeautifulSoup

web_root = "http://www.cosc.canterbury.ac.nz/greg.ewing/minecraft/mods"

def fatal(mess):
    sys.stderr.write(mess + "\n")
    sys.exit(1)

class Row(object):

    def __init__(self, cursor, row):
        d = self.__dict__
        for idx, col in enumerate(cursor.description):
            d[col[0]] = row[idx]
    
    def __str__(self):
        return str(self.__dict__)

def jinjafy(html_in):
    soup = BeautifulSoup(html_in)
    for node in soup.findAll(True, "jinja2"):
        text = " ".join(node.findAll(text = True))
        #print "jinjafy: found", text
        node.replaceWith(text)
    return str(soup)

def href(text, url):
    return '<a href="%s">%s</a>' % (url, text)

def download_href(mod_name, filename):
    return href(filename, "%s/%s/download/%s" % (web_root, mod_name, filename))

def extract_news(html_in):
    soup = BeautifulSoup(html_in)
    changelog = soup.find(id = "changelog")
    if changelog:
        dt = changelog.find("dt") or ""
        dd = changelog.find("dd") or ""
        #nlines = len(dd.findAll("br")) + 1
        nlines = len(textwrap.wrap(str(dd)))
        fsize = 14
        lheight = 18
        print "extract_news: dt =", dt
        print "extract_news: dd =", dd
        print "extract_news: nlines =", nlines
        tmpl = Template(open("news.jinja2").read())
        svg_out = tmpl.render(font_size = fsize, line_height = lheight,
            width = 790, height = nlines * lheight + 24,
            dt = dt, dd = dd)
        open("news.svg", "w").write(svg_out)

def mc_version_tuple(row):
    return map(int, row.mc_version.split("."))

def main():
    def pop_arg(default = None):
        if args:
            return args.pop(0)
        else:
            return default
    args = sys.argv[1:]
    mod_name = pop_arg()
    if not mod_name:
        fatal("Missing mod_name")
    src_filename = pop_arg("README.html")
    dst_filename = pop_arg("build/README.html")
    html_in = open(src_filename).read()
    extract_news(html_in)
    conn = sqlite3.connect("versions.db")
    conn.row_factory = Row
    curs = conn.cursor()
    rows = curs.execute("""select * from version""")
    data = rows.fetchall()
    data.sort(key = mc_version_tuple)
    for row in data:
        #print row
        mod_mc_version = getattr(row, 'mod_mc_version', None) or row.mc_version
        row.jar_href = download_href(mod_name, "%s-%s-mc%s.jar" % (mod_name, row.mod_version, mod_mc_version))
        row.doc_href = download_href(mod_name, "%s-%s-Doc.zip" % (mod_name, row.mod_version))
        row.src_href = download_href(mod_name, "%s-%s-mc%s-Source.zip" % (mod_name, row.mod_version, mod_mc_version))
        row.forge_href = href(row.forge_version, row.forge_link)
    html_jinja = jinjafy(html_in)
    #open("template.html", "w").write(html_jinja)
    tmpl = Template(html_jinja)
    html_out = tmpl.render(versions = data)
    open(dst_filename, "w").write(html_out)

main()
