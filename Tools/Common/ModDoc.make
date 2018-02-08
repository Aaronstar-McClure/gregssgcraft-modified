#-------------------------------------------------------------------------------
#
#   Generic Mod Documentation Makefile
#
#-------------------------------------------------------------------------------

#MODNAME := MyMod
#MODTITLE := My Mod
#MODSUBPKG := mymod

#MAJVER := 1
#MINVER := 0
#BUGVER := 0

include Version.make

MODVER := $(MAJVER).$(MINVER).$(BUGVER)
WEBDIR := web/minecraft/mods/$(MODNAME)
RELDOC := $(MODNAME)-$(MODVER)-Doc.zip
RELDST ?= .

reldoc: readme
	rm -f $(RELDST)/$(RELDOC)
	zip $(RELDST)/$(RELDOC) README.html
	if [ -e Doc ]; then zip -r $(RELDST)/$(RELDOC) Doc -x \*.DS_Store; fi

.PHONY: readme

readme:
	Tools/Common/genreadme $(MODNAME) README.in.html README.html

.PHONY: upload upload_doc upload_news

upload: upload_doc upload_news

upload_doc:
	cd $(RELDST); rsync --progress --times $(RELDOC) $(COSC):$(WEBDIR)/download
	ssh $(COSC) 'cd $(WEBDIR); unzip -o download/$(RELDOC)'

upload_news:
	if [ -e news.svg ]; then rsync --progress --times news.svg $(COSC):$(WEBDIR); fi

#-------------------------------------------------------------------------------

PROJECT ?= $(MODNAME)
BACKUP_SUBSUBDIR := Common

include Tools/Common/BackupCommon.make
