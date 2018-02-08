#-------------------------------------------------------------------------------
#
#   Convert json .smeg file to .rib
#
#-------------------------------------------------------------------------------

import os, sys, json

#Format 48 54 1

preamble = """\
#Format 40 45 1
Format 40 84 1
Display "%(filename)s" "png" "rgba"
#ScreenWindow -0.707 0.707 -0.816 0.816
ScreenWindow -0.707 0.707 -1.5 1.5
ColorSamples [1 0 0 0 1 0 0 0 1] [1 0 0 0 1 0 0 0 1]
Translate 0 0 5
Scale 1 1 -1
Rotate 30 1 0 0
Rotate -45 0 1 0
WorldBegin
	LightSource "distantlight" "to" [0 -1 0] "intensity" 1.0
	LightSource "distantlight" "to" [-1 0 0] "intensity" 0.8
	LightSource "distantlight" "to" [0 0 -1] "intensity" 0.6
	Rotate -90 0 1 0
	Surface "matte"
"""

postamble = """\
WorldEnd
"""

colors = [
	"Color [0.25 0.5 1.0]",
	"Color [1 0 0]",
	"Color [0.25 1 0]",
	"Color [0.25 0.5 1.0]",
]

class J(object):

	def __repr__(self):
		return "J(%s)" % ",".join("%s = %s" % item for item in self.__dict__.iteritems())

def j(data):
	if isinstance(data, dict):
		obj = J()
		for name, value in data.iteritems():
			setattr(obj, name, j(value))
	elif isinstance(data, list):
		obj = [j(item) for item in data]
	else:
		obj = data
	return obj

def put(f, *args):
	f.write("  %s\n" % " ".join(map(str, args)))

def write_face(f, face):
	#print face.__dict__.keys()
	tex = min(face.texture, len(colors) - 1)
	put(f, colors[tex])
	v = face.vertices
	for t in face.triangles:
		put(f, 'Polygon "P" [')
		for i in t:
			p = v[i]
			put(f, *p[:3])
		put(f, ']')
		put(f, '"N" [')
		for i in t:
			put(f, *v[i][3:6])
		put(f, ']')

def main():
	args = sys.argv[1:]
	inpath = args[0]
	if len(args) >= 2:
		outpath = args[1]
	else:
		outpath = os.path.splitext(inpath)[0] + ".rib"
	if len(args) >= 3:
		pngpath = args[2]
	else:
		pngpath = os.path.splitext(outpath)[0] + ".png"
	#print outpath
	f = open(inpath)
	smeg = j(json.load(f))
	f.close()
	#print smeg.__dict__.keys()
	f = open(outpath, "w")
	f.write(preamble % dict(filename = pngpath))
	for face in smeg.faces:
		write_face(f, face)
	f.write(postamble)
	f.close()

main()
