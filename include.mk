# the following may optionally defined on the command line or in config.mk
# CHDKPTP=<path to chdkptp exe or shell script>
# use chdkptp for inline instead of python
# CHDKPTP_INLINE=1
# more verbose output#
# VERBOSE=1
# make remoteshoot glue files (requires chdkptp)
# MAKE_GLUE=1
# options for chdkptp connect in upload
# CAMSPEC=(options for chdkptp -c)
#
-include $(TOPDIR)/config.mk

ifeq ($(OS),Windows_NT)
CHDKPTP ?= chdkptp.exe
else
CHDKPTP ?= chdkptp.sh
endif
CHDKPTP_CONNECT=-c'$(CAMSPEC)'

BUILTDIR=$(TOPDIR)/built
SRCDIR=$(TOPDIR)/src
LIBDIR=$(SRCDIR)/reylib
DISTDIR=$(TOPDIR)/dist
