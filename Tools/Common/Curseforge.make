#-------------------------------------------------------------------------------
#
#   Generic Mod Makefile - Curseforge upload
#
#-------------------------------------------------------------------------------

cfupload:
	Tools/Common/cfupload $(CURSE_PROJECT_ID) $(MODVER) $(MC) $(RELJAR) ../Common/README.in.html
