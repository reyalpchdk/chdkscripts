# config.mk may optionally define
# CHDKPTP=<path to chdkptp exe or shell script>
# use chdkptp for inline instead of python
# CHDKPTP_INLINE=1
# more verbose output#
# VERBOSE=1
# make remoteshoot glue files (requires chdkptp)
# MAKE_GLUE=1
-include $(TOPDIR)/config.mk

OUTDIR=$(TOPDIR)/built
SRCDIR=$(TOPDIR)/src
LIBDIR=$(SRCDIR)/reylib
DISTDIR=$(TOPDIR)/dist
DISTSTAGEDIR=$(TOPDIR)/dist/$(SCRIPTNAME)

ifeq ($(OS),Windows_NT)
CHDKPTP ?= chdkptp.exe
else
CHDKPTP ?= chdkptp.sh
endif

ifdef CHDKPTP_INLINE
ifdef VERBOSE
INLINE_OPTS=verbose=true
endif
INLINE_CMD=$(CHDKPTP) -e'exec m=require"extras/inlinemods"' -e='exec m.process_file("$<","$@",{modpath="$(SRCDIR)",$(INLINE_OPTS)})'
else
ifdef VERBOSE
INLINE_OPTS=-v
endif
INLINE_CMD=$(TOPDIR)/tools/buildscript.py $< $@ -l $(SRCDIR) $(INLINE_OPTS)
endif

GLUE_CMD=$(CHDKPTP) -e'exec require"chdkscripthdr".new_header{file="$<"}:make_glue_file("$(GLUETPLFILE)","$@")'

OUTFILE=$(OUTDIR)/$(SCRIPTNAME).lua
LIBFILES=$(foreach lib,$(LIBS),$(LIBDIR)/$(lib).lua)
DISTZIP=$(DISTDIR)/$(SCRIPTNAME).zip
READMESRC=readme.wiki
READMEDIST=$(DISTSTAGEDIR)/readme-$(SCRIPTNAME).txt

ifdef MAKE_GLUE
ifdef GLUETPLNAME
GLUETPLFILE=$(SRCDIR)/$(SCRIPTNAME)/$(GLUETPLNAME)
GLUEFILE=$(OUTDIR)/chdkptp/$(SCRIPTNAME)_chdkptp.lua
endif
endif

.PHONY: clean clean-built clean-dist clean-glue script dist glue upload

script: $(OUTFILE)
dist: $(DISTZIP)
glue: $(GLUEFILE)

upload: $(OUTFILE)
	$(CHDKPTP) -c -e'u $(OUTFILE) CHDK/SCRIPTS'

$(OUTFILE): $(SCRIPTNAME)-main.lua $(LIBFILES)
	$(INLINE_CMD)

$(DISTZIP): $(OUTFILE) $(READMEFILE) $(GLUEFILE)
	mkdir -p $(DISTSTAGEDIR)
	cp $(READMESRC) $(READMEDIST)
	rm -f $(DISTZIP)
	zip -j $(DISTZIP) $(OUTFILE) $(READMEDIST) $(GLUEFILE)

ifdef GLUEFILE
$(GLUEFILE): $(OUTFILE) $(GLUETPLFILE)
	$(GLUE_CMD)

clean: clean-glue

clean-glue:
	rm -f $(GLUEFILE)
endif

clean: clean-built clean-dist

clean-built:
	rm -f $(OUTFILE)


clean-dist:
	rm -rf $(DISTSTAGEDIR)
	rm -f $(DISTZIP)

