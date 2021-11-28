# see include.mk for configurable settings
# to build a single script, specify the bare script name without .lua, like
#  make rawopint
# to build other targets for a single script, use the TARGET variable, like
#  make rawopint TARGET="clean dist upload"
# to build everything to distributable zip files, use
#  make allzip
TOPDIR=.
include $(TOPDIR)/include.mk
SCRIPTS=rawopint fixedint contae
DISTZIPS=$(foreach script,$(SCRIPTS),$(script).zip)

# target for make scriptname
TARGET ?= script

.PHONY: clean allscript allzip allup $(SCRIPTS) $(DISTZIPS)


allscript: $(SCRIPTS)

allzip: $(DISTZIPS)

allup: allscript
	cd $(BUILTDIR) && $(CHDKPTP) $(CHDKPTP_CONNECT) -e'mup $(patsubst %,%.lua,$(SCRIPTS)) CHDK/SCRIPTS'

$(SCRIPTS):
	$(MAKE) -C ./src/$@ $(TARGET)

$(DISTZIPS):
	$(MAKE) -C ./src/$(patsubst %.zip,%,$@) dist

clean:
	@for i in $(SCRIPTS); do \
		$(MAKE) -C ./src/$$i clean || exit 1; \
	done

clean-built:
	@for i in $(SCRIPTS); do \
		$(MAKE) -C ./src/$$i clean-built || exit 1; \
	done

clean-dist:
	@for i in $(SCRIPTS); do \
		$(MAKE) -C ./src/$$i clean-dist || exit 1; \
	done
