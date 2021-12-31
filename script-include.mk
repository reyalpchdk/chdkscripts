# variables and generic rules for script makefiles
include $(TOPDIR)/include.mk

DISTSTAGEDIR=$(TOPDIR)/dist/$(SCRIPTNAME)

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

GLUE_CMD=$(CHDKPTP) -e'exec require"chdkscripthdr".new_header{file="$<"}:make_glue_file("$(GLUETPLFILE)","$@",{camfile="$(SCRIPTNAME).lua"})'

OUTFILE=$(BUILTDIR)/$(SCRIPTNAME).lua
LIBFILES=$(foreach lib,$(LIBS),$(LIBDIR)/$(lib).lua)
DISTZIP=$(DISTDIR)/$(SCRIPTNAME).zip
READMESRC=readme.wiki
READMEDIST=$(DISTSTAGEDIR)/readme-$(SCRIPTNAME).txt

ifdef MAKE_GLUE
ifdef GLUETPLNAME
GLUETPLFILE=$(SRCDIR)/$(SCRIPTNAME)/$(GLUETPLNAME)
GLUEFILE=$(BUILTDIR)/chdkptp/$(SCRIPTNAME)_chdkptp.lua
endif
endif

.PHONY: clean clean-built clean-dist clean-glue script dist glue upload

script: $(OUTFILE)
dist: $(DISTZIP)
glue: $(GLUEFILE)

upload: $(OUTFILE)
	$(CHDKPTP) $(CHDKPTP_CONNECT) -e'u $(OUTFILE) CHDK/SCRIPTS'

$(OUTFILE): $(SCRIPTNAME)-main.lua $(LIBFILES)
	$(INLINE_CMD)

$(READMEDIST): $(READMESRC)
	mkdir -p $(DISTSTAGEDIR)
	cp $(READMESRC) $(READMEDIST)

$(DISTZIP): $(OUTFILE) $(READMEDIST) $(GLUEFILE) $(GLUETPLFILE)
	mkdir -p $(DISTSTAGEDIR)
	rm -f $(DISTZIP)
	zip -j $(DISTZIP) $(OUTFILE) $(READMEDIST) $(GLUEFILE) $(GLUETPLFILE)

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

