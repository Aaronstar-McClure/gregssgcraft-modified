#-------------------------------------------------------------------------------
#
#	SGCraft - Makefile - MC1.10
#
#-------------------------------------------------------------------------------

include ../Common/Params.make

MODID := sgcraft
MODSUBPKG := sg

CURSE_PROJECT_ID := 241583

# For README file
# Forge version moved to mcp/ForgeVersion.make
#FORGE_VERSION ?= 12.18.2.2099
#FORGE_LINK ?= http://files.minecraftforge.net/maven/net/minecraftforge/forge/index_1.10.2.html
IC2_VERSION := 2-2.6.105
CC_VERSION :=
OC_VERSION := 1.6.0.4

BACKUP_EXCLUDE_EXTRA = --exclude Artwork --exclude Audio --exclude Images

#BACKUP_EXTRA = backup_sync

include ../Common/VersionDB.make
include Tools/ModCode.make

SRC_INCLUDE += BUILDING.txt lib/README.txt
#RELSRC := $(MODNAME)-$(MODVER)-mc$(MC)-Source-1.zip

.PHONY: resources ccexamples ocexamples update_version_db backup_sync

#compile: resources
#
#resources:
#	cp -r -p ../Common/src/resources/* src/resources

test_ic2:
	$(MAKE) OBF_PROFILE=ic2 test_jar

run_ic2:
	$(MAKE) OBF_PROFILE=ic2 run_jar

test_rf:
	$(MAKE) OBF_PROFILE=rf test_jar

run_rf:
	$(MAKE) OBF_PROFILE=rf run_jar

test_cc:
	$(MAKE) OBF_PROFILE=cc test_jar

run_cc:
	$(MAKE) OBF_PROFILE=cc run_jar

test_oc:
	$(MAKE) OBF_PROFILE=oc test_jar

run_oc:
	$(MAKE) OBF_PROFILE=oc run_jar
