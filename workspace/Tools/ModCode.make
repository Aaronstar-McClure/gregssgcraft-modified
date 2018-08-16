#-------------------------------------------------------------------------------
#
#   Generic Mod Makefile for one version of a multi-version set - MC 1.10
#
#-------------------------------------------------------------------------------

#MODNAME := MyMod
#MODTITLE := My Mod
#MODSUBPKG := mymod

#MAJVER := 1
#MINVER := 0
#BUGVER := 0

include ../Common/Version.make
include mcp/ForgeVersion.make

SRCDIRS ?= src/base src/mod

SERVER_SIDE ?= True

#MC ?= 1.8.9
MCMIN ?= $(MC)
MCMAX ?= $(MC)

MODID ?= $(MODNAME)
MODVER := $(MAJVER).$(MINVER).$(BUGVER)
MODPKG ?= gcewing/$(MODSUBPKG)
MODPKGNAME ?= $(subst /,.,$(MODPKG))
ASSETKEY ?= $(subst /,_,$(MODPKG))

MCP ?= mcp

INSTALLATION := /Local/Games/Minecraft/Profiles/1.6
PROFILE ?= ModTesting-$(MC)
SERVER ?= game/server

# Location of game directories for testing
GAMELOC ?= $(HERE)/game

# Subdir of GAMELOC for unobfuscated testing, used by targets: test, run
TEST_PROFILE ?= plain

# Subdir of GAMELOC for obfuscated testing, used by targets: test_jar, run_jar
OBF_PROFILE ?= obf

HERE := $(shell pwd)
SERVER_PROFILE ?= server
TEST_GAMEDIR ?= $(GAMELOC)/$(TEST_PROFILE)
TEST_MODDIR := $(TEST_GAMEDIR)/mods
OBF_GAMEDIR ?= $(GAMELOC)/$(OBF_PROFILE)
#OBF_MODDIR := $(INSTALLATION)/profiles/$(PROFILE)/mods
OBF_MODDIR := $(OBF_GAMEDIR)/mods
#SERVER_MODDIR := $(SERVER)/mods
SERVER_MODDIR := $(GAMELOC)/$(SERVER_PROFILE)/mods

RUN_JAVA_HOME ?= /Library/Java/JavaVirtualMachines/jdk1.8.0.jdk/Contents/Home

export MODID MODNAME MODTITLE MODPKG MODPKGNAME MAJVER MINVER BUGVER MODVER MCMIN MCMAX

PROJECT ?= $(MODNAME)
SRC_INCLUDE := build.gradle gradle.properties Makefile $(SRCDIRS) src/resources Tools

CPATH_FORGE ?= $(MCP)/`cd $(MCP); make cpath_forge`
CPATH_MCLIBS ?= `cd $(MCP); make cpath`
CPATH ?= $(CPATH_FORGE):$(CPATH_MCLIBS):lib/'*'
SPATH ?= src/mod:src/base:api:lib
CDEST := build/classes/main
JDEST := $(TEST_MODDIR)/$(MODNAME).jar

MANIFEST ?= src/mod/$(MODPKG)/MANIFEST.MF

RELJAR := $(MODNAME)-$(MODVER)-mc$(MC).jar
TSTJAR := build/libs/$(RELJAR)
RELZIP := $(MODNAME)-$(MODVER)-mc$(MC).zip
#RELDOC := $(MODNAME)-$(MODVER)-Doc.zip
RELSRC := $(MODNAME)-$(MODVER)-mc$(MC)-Source.zip
RELDST ?= .
WEBDIR := web/minecraft/mods/$(MODNAME)

#JFLAGS = -Xlint:deprecation
GRADLE_OPTIONS ?= --offline
MCUSER = gcewing
MCUUID = 25085db5a39944d28f34f0b58c18b164

SC := scalac $(SFLAGS)
JC := javac $(JFLAGS)

JARCONTENTS ?= \
	-C $(1) $(MODPKG) \
	-C src/mod assets \
	$(EXTRA_JARCONTENTS)

JARCLASSDIRS ?= $(MODPKG)

BUILDJAR = \
	for item in `cd $(2); find $(JARCLASSDIRS) -name '*.class'`; do \
		args="$$args -C $(2) $$item"; \
	done; \
	if [ -e src/resources ]; then \
		for item in `cd src/resources; echo *`; do \
			args="$$args -C src/resources $$item"; \
		done; \
	fi; \
	if [ -e $(MANIFEST) ]; then \
		jar cfm $(1) $(MANIFEST) $$args; \
	else \
		jar cf $(1) $$args; \
	fi

POSTPROCESS_JAR = \
	if [ -e src/mod/$(MODPKG)/overrides ]; then \
		jar=$(strip $(1)); \
		echo Postprocessing $$jar; \
		tmpdir=build/tmpjar; \
		tmpfile=$$tmpdir/$(notdir $(1)); \
		mkdir -p $$tmpdir; \
		Tools/rename_overrides $$jar $$tmpfile; \
		mv $$tmpfile $$jar; \
	fi

cpath:
	@echo $(CPATH)

classpath:
	@echo $(CPATH):$(SPATH) | tee classpath.txt

#----------------------------------------------------------------------------------

test: compile install run

build_jar: compile assemble_jar install_jar

test_jar: build_jar run_jar

#test_server: compile install jar install_jar run_server

release: compile assemble_jar relpkg

#-----------------------------------------------------------------------------------------------

gradle.properties: Makefile Tools/ModCode.make ../Common/Version.make
	(echo version = $(MODVER)-mc$(MC); \
	 echo mcversion = [$(MCMIN),$(MCMAX)]; \
	 echo group = $(MODPKGNAME); \
	 echo jarName = $(MODNAME)) > $@

#-----------------------------------------------------------------------------------------------

src_dirs:
	mkdir -p src/base/$(MODPKG) src/mod/$(MODPKG)
	rm -f src-base src-gcewing
	ln -s src/base/$(MODPKG) src-base
	ln -s src/mod/$(MODPKG) src-gcewing

resource_dirs:
	mkdir -p src/resources/assets/$(ASSETKEY)/textures/blocks
	mkdir -p src/resources/assets/$(ASSETKEY)/textures/items
	rm -f textures
	ln -s src/resources/assets/$(ASSETKEY)/textures .

#-----------------------------------------------------------------------------------------------

SCALA_SOURCES := `find $(SRCDIRS) -name '*.scala'`

scala_sources:
	@echo $(SCALA_SOURCES)

clean:
	@echo Clearing class files
	@rm -rf $(CDEST)/*

compile: common_src $(CDEST) info m4base lang
	@set -e; \
	src=$(SCALA_SOURCES); \
	if [ "$$src" ]; then \
		echo Compiling Scala sources; \
		$(SC) -classpath $(CPATH) -sourcepath $(SPATH) -d $(CDEST) $$src; \
	fi
	@src=`find $(SRCDIRS) -name '*.java'`; \
	if [ "$$src" ]; then \
		echo Compiling Java sources; \
		$(JC) -classpath $(CPATH):$(CDEST) -sourcepath $(SPATH) -d $(CDEST) $$src; \
	fi

common_src:
	@if [ -e ../Common/src ]; then \
		echo Copying common source; \
		cp -r -p ../Common/src/* src; \
	fi

lang:
	@if [ -e src/$(MODNAME).names ]; then \
		echo Generating language file; \
		Tools/genlang $(MODNAME) $(MODPKGNAME) src/$(MODNAME).names; \
	fi

$(CDEST):
	mkdir -p $(CDEST)

test_info:
	Tools/geninfo

info:
	@if [ -e src/mod/$(MODPKG)/Info.java ]; then \
		echo Generating Info.java; \
		Tools/geninfo > src/mod/$(MODPKG)/Info.java; \
	fi

m4base:
	@if [ -e src/base ]; then \
		echo Preprocessing base; \
		(cd src/base/$(MODPKG); \
	 		for f in *.java; do \
	 			m4 -P -DMOD_PACKAGE=$(MODPKGNAME) < ../../../../Base/$$f > $$f; \
	 		done); \
	 fi

install:
	mkdir -p $(TEST_MODDIR)
	rm -f $(JDEST)
	@echo Building $(JDEST)
	@$(call BUILDJAR, $(JDEST), build/classes/main)
	@$(call POSTPROCESS_JAR, $(JDEST))

run:
	export GAMEDIR=$(TEST_GAMEDIR); cd $(MCP); make run

#run:
#	cd $(MCP); ./startclient.sh $(RUNARGS) $(MCUSER)

#-----------------------------------------------------------------------------------------------

assemble_jar: gradle.properties info m4base gradle_jar insert_manifest postprocess_jar

gradle_jar:
	rm -rf build/libs/$(MODNAME)-*.jar build/resources/*
	./gradlew $(GRADLE_OPTIONS) -x compileJava assemble

insert_manifest:
	if [ -e $(MANIFEST) ]; then \
		jar umf $(MANIFEST) $(TSTJAR); \
	fi

postprocess_jar:
	@$(call POSTPROCESS_JAR, $(TSTJAR))

#-----------------------------------------------------------------------------------------------

install_jar:
		mkdir -p $(OBF_MODDIR)
		rm -f $(OBF_MODDIR)/$(MODNAME)-*
		cp $(TSTJAR) $(OBF_MODDIR)
ifeq ($(SERVER_SIDE), True)
		mkdir -p $(SERVER_MODDIR)
		rm -f $(SERVER_MODDIR)/$(MODNAME)-*
		if [ -e $(SERVER_MODDIR) ]; then cp $(TSTJAR) $(SERVER_MODDIR); fi
endif

#-----------------------------------------------------------------------------------------------

run_jar:
	JAVA_HOME=$(RUN_JAVA_HOME) Tools/mclaunch $(INSTALLATION) -p $(PROFILE) -u $(MCUSER) --uuid $(MCUUID) --gameDir $(OBF_GAMEDIR)

run_server:
	cd $(SERVER); start

test_client:
	$(MAKE) OBF_PROFILE=client test_jar

run_client:
	$(MAKE) OBF_PROFILE=client run_jar

#-----------------------------------------------------------------------------------------------

relpkg: reljar relsrc update_version_db

reljar:
	cp build/libs/$(RELJAR) $(RELDST)

# reldoc:
# 	if [ -e Doc ]; then zip -r $(RELDST)/$(RELDOC) Doc; fi

# reldoc: build/README.html
# 	rm -f $(RELDST)/$(RELDOC)
# 	cd build; zip -r $(RELDOC) README.html
# 	mv build/$(RELDOC) $(RELDST)
# 	if [ -e Doc ]; then zip -r $(RELDST)/$(RELDOC) Doc; fi

# build/%.html: %.html Makefile
# 	m4 -P -DMODNAME=$(MODNAME) -DMODVER=$(MODVER) -DMCVER=mc$(MC) $< > $@

relsrc:
	rm -f $(RELDST)/$(RELSRC)
	zip -r $(RELDST)/$(RELSRC) $(SRC_INCLUDE)
	
#----------------------------------------------------------------------------------

# upload:
# 	cd $(RELDST); rsync --progress --times $(RELJAR) $(RELDOC) $(RELSRC) $(COSC):$(WEBDIR)/download
# 	ssh $(COSC) 'cd $(WEBDIR); unzip -o download/$(RELDOC)'

upload:
	cd $(RELDST); rsync --progress --times $(RELJAR) $(RELSRC) $(COSC):$(WEBDIR)/download

include Tools/Common/Curseforge.make

#----------------------------------------------------------------------------------

include Tools/Common/ModVersionDB.make

#----------------------------------------------------------------------------------

include Tools/Backup.make

BACKUP_EXCLUDE += --exclude Architecture-Releases
