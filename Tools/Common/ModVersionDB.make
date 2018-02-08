#-------------------------------------------------------------------------------
#
#   Version database management
#
#-------------------------------------------------------------------------------

VERSION_DB ?= ../Common/versions.db

FORGE_VERSION ?= FORGE_VERSION_missing
FORGE_LINK ?= FORGE_LINK_missing

create_version_db:
	sqlite3 $(VERSION_DB) \
	 "CREATE TABLE version(mc_version, mod_version, forge_version, forge_link $(VERSION_DB_EXTRA_FIELDS));"

update_version_db:
	@if [ ! -f $(VERSION_DB) ]; then echo "$(VERSION_DB)" not found; exit 1; fi
	sqlite3 $(VERSION_DB) \
	 "delete from version where mc_version = '$(MC)'; \
	 insert into version(mc_version, mod_version, forge_version, forge_link $(VERSION_DB_EXTRA_FIELDS)) \
	 values ('$(MC)', '$(MODVER)', '$(FORGE_VERSION)', '$(FORGE_LINK)' $(VERSION_DB_EXTRA_VALUES));"
