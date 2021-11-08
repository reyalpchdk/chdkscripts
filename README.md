# Overview
This repo contains a collection of [CHDK](https://chdk.fandom.com/wiki/CHDK) Lua
scripts, modules, and associated tools.

# Scripts

## rawopint
Fast, accurate intervalometer, suitable for sunrises, sunsets and similar. Uses raw image
data for exposure changes, providing smooth, accurate exposure control in almost any illumination.

* [Release](https://app.box.com/s/k4w85tnsf4gl2pvwh4mvu35vejkup53j) 0.25
* [Development build](built/rawopint.lua) ([download](built/rawopint.lua?raw=1))
* [Source + documentation](src/rawopint)
* [Forum Thread](https://chdk.setepontos.com/index.php?topic=12697.0)

## fixedint
Astrophotography oriented intervalometer for long exposure, timelapse and generating image
stacks. Shoots all shots with the same exposure.

* [Release](https://app.box.com/s/nqzoeubgxkgnitz7o7wotvbe90ejegni) 1.3
* [Development build](built/fixedint.lua) ([download](built/fixedint.lua?raw=1))
* [Source + documentation](src/fixedint)
* [Forum Thread](https://chdk.setepontos.com/index.php?topic=12695.0)

## contae
Uses raw image data to proved auto-exposure while shooting in continuous mode.

* [Release](https://app.box.com/s/d1xeg34h2lyla3jz30sb9khgqfg57ul8) 0.12
* [Development build](built/contae.lua) ([download](built/contae.lua?raw=1))
* [Source + documentation](src/contae)
* [Forum Thread](https://chdk.setepontos.com/index.php?topic=12696.0)

# Inline module build system
For modularity and ease of code re-use, these scripts are composed of Lua modules,
which are then "inlined" into a single file for ease of distribution and installation.

The main scripts are found in `src/<scriptname>`, and the modules are in `src/reylib`

Builds of the current development source can be found in the [built](built/) directory. While
the development builds in the master branch should generally run, they may be broken,
have features in flux, or be out of sync with the documentation.

If you want to make modifications to any of the scripts for your own use, you can
edit the built script directly rather than using the build system.

If you do want to use the build system, you need GNU make and python 3 or
[chdkptp](https://app.assembla.com/spaces/chdkptp/wiki). To build a script, use
`make <scriptname>` (without .lua) in the top level directory. See the makefiles
for additional targets.

# Lua Modules
There may be documentation for these someday, but for now, [use the source](src/reylib)

* `clkstart.lua` - Start a script at a particular time
* `csvlog.lua` - Log values to csv file
* `disp.lua` - Control display / backlight
* `focus.lua` - Control focus overrides, selecting supported focus override mode
* `rawexp.lua` - Calculate exposure from raw data of previous shot, with smoothing, limits
* `shutdown.lua` - Trigger shutdown on conditions like low batter, low SD card space
* `strutil.lua` - String utility functions

Each module is a Lua table which encapsulates the required state and methods. However,
some modules assume that other modules are present, for example, the exposure module requires
that the log module be included and configured with the appropriate fields.

To use the modules in your own scripts, you can use `buildscript.py` to inline them
like the scripts here, copy the relevant inline blocks manually. The modules should also
work with regular Lua `require` if installed in CHDK/LUALIB on your SD card, but this
is not generally tested. If you distribute a script using these modules, it's strongly
recommended that you inline them.

# Tools
* `buildscript.py` - Used to build scripts
* `rawopint_log_analysis.py` - Library for loading and analyzing rawopint logs
* `rawopint-analysis.ipynb` - Sample jupyter notebook

# Contact
The [CHDK forum](https://chdk.setepontos.com/index.php) is preferred for general
questions and discussion. Github pull requests and issues can be used to report
bugs and suggest code changes.

The author can be emailed at reyalp (at) gmail dot com, but the CHDK forum is
the preferred place for discussion related to these scripts.
