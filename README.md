# Overview
This repo contains a collection of [CHDK](https://chdk.fandom.com/wiki/CHDK) Lua
scripts, modules, and associated tools.

# Scripts

## rawopint
Fast, accurate intervalometer, suitable for sunrises, sunsets and similar. Uses raw image
data for exposure changes, providing smooth, accurate exposure control in almost any illumination.

* [Release](https://github.com/reyalpchdk/chdkscripts/releases/download/v25.03.0/rawopint-0.26.zip) 0.26
* [Previous release](https://app.box.com/s/k4w85tnsf4gl2pvwh4mvu35vejkup53j) 0.25
* [Development build](built/rawopint.lua) ([download](built/rawopint.lua?raw=1))
* [Source + documentation](src/rawopint)
* [Forum Thread](https://chdk.setepontos.com/index.php?topic=12697.0)

## fixedint
Astrophotography oriented intervalometer for long exposure, timelapse and generating image
stacks. Shoots all shots with the same exposure.

* [Release](https://github.com/reyalpchdk/chdkscripts/releases/download/v25.03.0/fixedint-1.4.zip) 1.4
* [Previous release](https://app.box.com/s/nqzoeubgxkgnitz7o7wotvbe90ejegni) 1.3
* [Development build](built/fixedint.lua) ([download](built/fixedint.lua?raw=1))
* [Source + documentation](src/fixedint)
* [Forum Thread](https://chdk.setepontos.com/index.php?topic=12695.0)

## contae
Uses raw image data to proved auto-exposure while shooting in continuous mode.

* [Release](https://github.com/reyalpchdk/chdkscripts/releases/download/v25.03.0/contae-0.13.zip) 0.13
* [Previous release](https://app.box.com/s/d1xeg34h2lyla3jz30sb9khgqfg57ul8) 0.12
* [Development build](built/contae.lua) ([download](built/contae.lua?raw=1))
* [Source + documentation](src/contae)
* [Forum Thread](https://chdk.setepontos.com/index.php?topic=12696.0)

# chdkptp tethered shooting support
The directory [built/chdkptp](built/chdkptp/) contains "glue" scripts which can
allow the use of some of the scripts with chdkptp remoteshoot.

# Inline module build system
For modularity and ease of code re-use, these scripts are composed of Lua modules,
which are then "inlined" into a single file for ease of distribution and installation.

The main scripts are found in `src/<scriptname>`, and the modules are in `src/reylib`

Builds of the current development source are checked in for the convenience of users
who do not have the build environment configured. They can be found in the [built](built/)
directory. While the development builds in the master branch should generally run,
they may be broken, have features in flux, or be out of sync with the documentation.
For released builds, see the release links above.

If you want to make modifications to any of the scripts for your own use, you can
edit the built script directly rather than using the build system.

If you do want to use the build system, you need GNU compatible make and python 3
or [chdkptp](https://app.assembla.com/spaces/chdkptp/wiki). Use `make allscript` to
build all the scripts. Other global targets include `allzip` to build distributable
zips, `clean` to remove all built files, and `allup` to upload all to the camera.

To build a single script, use `make <scriptname>` (without .lua) in the top level
directory. To make other script-specific targets, use `make <scriptname> TARGET="targets"`, like
```
make rawopint TARGET="clean dist upload"
```

You can create a file called `config.mk` to set build settings. See `include.mk` for descriptions.

The build system can also produce "glue" files which allow some scripts to be used
with chdkptp remoteshoot. chdkptp must be installed to generate these files, and you must
set MAKE\_GLUE

# Lua Modules
There may be documentation for more of these someday, but for now, [use the source](src/reylib) if there is no documentation link

* `clkstart.lua` - Wait for a particular time to start shooting
* `disp.lua` - Control display / backlight
* `focus.lua` - Control focus overrides, selecting supported focus override mode ([documentation](src/reylib/focus.md))
* `rawexp.lua` - Calculate exposure from raw data of previous shot, with smoothing, limits
* `shutdown.lua` - Trigger shutdown on conditions like low batter, low SD card space
* `strutil.lua` - String utility functions
* `xsvlog.lua` - Log values to CSV/TSV file ([documentation](src/reylib/xsvlog.md))

Each module is a Lua table which encapsulates the required state and methods. However,
some modules assume that other modules are present, for example, the exposure module requires
that the log module be included and configured with the appropriate fields.

To use the modules in your own scripts, you can use `buildscript.py` to inline them
like the scripts here, or copy the relevant inline blocks manually. The modules should
also work with regular Lua `require` if installed in CHDK/LUALIB on your SD card, but this
is not generally tested. If you distribute a script using these modules, it's strongly
recommended that you inline them.

# Tools
* `buildscript.py` - Used to build scripts
* `rawopint_log_analysis.py` - Python class for loading and analyzing rawopint logs
* `rawopint_log_plot.py` - Subclass of analysis class with matplotlib-based plotting methods
* [rawopint-analysis-tutorial.ipynb](tools/rawopint-analysis-tutorial.ipynb) - [Jupyter notebook](https://jupyter.org/) with some documentation. Viewable online, but interactive features are disabled.
* `rawopint-analysis.ipynb` - Minimal [jupyter notebook](https://jupyter.org/) for use as a starting point for your own logs.

# Contact
The [CHDK forum](https://chdk.setepontos.com/index.php) is preferred for general
questions and discussion. Github pull requests and issues can be used to report
bugs and suggest code changes.

The author can be contacted by email at reyalp (at) gmail dot com, but the CHDK forum is
the preferred place for discussion related to these scripts.

The author can also sometimes be found in [#chdk](https://web.libera.chat/?channels=#chdk)
on [libera.chat](https://libera.chat/).
