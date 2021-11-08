OUTDIR=$(TOPDIR)/built
SRCDIR=$(TOPDIR)/src
LIBDIR=$(SRCDIR)/reylib
DISTDIR=$(TOPDIR)/dist
DISTSTAGEDIR=$(TOPDIR)/dist/$(SCRIPTNAME)

ifdef CHDKPTP_BUILD
HOSTPLATFORM:=$(patsubst MINGW%,MINGW,$(shell uname -s))
ifeq ($(HOSTPLATFORM),MINGW)
CHDKPTP=chdkptp.exe
else
CHDKPTP=chdkptp.sh
endif
ifdef VERBOSE
BUILD_OPTS=verbose=true
endif
BUILD=$(CHDKPTP) -e'exec m=require"extras/inlinemods"' -e='exec m.process_file("$<","$@",{modpath="$(SRCDIR)",$(BUILD_OPTS)})'
else
ifdef VERBOSE
BUILD_OPTS=-v
endif
BUILD=$(TOPDIR)/tools/buildscript.py $< $@ -l $(SRCDIR) $(BUILD_OPTS)
endif

OUTFILE=$(OUTDIR)/$(SCRIPTNAME).lua
LIBFILES=$(foreach lib,$(LIBS),$(LIBDIR)/$(lib).lua)
DISTZIP=$(DISTDIR)/$(SCRIPTNAME).zip
READMESRC=readme.wiki
READMEDIST=$(DISTSTAGEDIR)/readme-$(SCRIPTNAME).txt

.PHONY: clean clean-built clean-dist script dist

script: $(OUTFILE)
dist: $(DISTZIP)

$(OUTFILE): $(SCRIPTNAME)-main.lua $(LIBFILES)
	$(BUILD)

$(DISTZIP): $(OUTFILE) $(READMEFILE)
	mkdir -p $(DISTSTAGEDIR)
	cp $(READMESRC) $(READMEDIST)
	rm -f $(DISTZIP)
	zip -j $(DISTZIP) $(OUTFILE) $(READMEDIST)

clean: clean-built clean-dist

clean-built:
	rm -f $(OUTFILE)

clean-dist:
	rm -rf $(DISTSTAGEDIR)
	rm -f $(DISTZIP)

