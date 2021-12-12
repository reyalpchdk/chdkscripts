csvlog.lua - CSV logfile library for CHDK scripts

# Overview
This library is designed to record sequences of values from a script, such as exposure, timing and debugging information for each shot in an intervalometer.
* The script defines a set of named columns in the log file using `csvlog.new`. The column names are written as header to the log.
* Column values are set by passing name/value pairs to `log:set`, or other functions for special cases described below.
* Rows are written to the log when `log:write` is called, typically once per shot or main loop iteration. Any columns without a defined value are written as an empty cells. After a row is written, all column values are reset to empty.

This has several advantages over the more typical approach where various parts of script write text directly to the log, or collect values in ad-hoc variables which are later written with a giant `string.format` expression
* Log structure is kept consistent, allowing for easy processing and analysis on a PC.
* Values can be logged directly in the code that calculates or uses them. Any values that aren't set on a particular codepath are output as an empty cell.
* The log library manages all output, providing for alternative buffering modes and destinations.

In the description below, `csvlog` refers to the module returned by `require`, and `log` refers to a log instance created with `csvlog.new`

# Initializing the log
The log is initialized by passing a table of options to `csvlog.new`, like
```lua
csvlog = require'csvlog'
log = csvlog.new{
-- name is required
	name="A/myscript.csv",
-- the following are defaults
--	append=false
--	dummy=false
--	buffer_mode='os'
--	quote_mode='auto'

-- columns - required
	cols={
		'date',
		'time',
		'exp',
		'start',
		'exp_start',
		'tsensor',
		'desc',
	},
-- function columns, optional
	funcs={
		exp=get_exp_count,
		tsensor=function()
			return get_temperature(1)
		end,
	},
-- table columns, optional
	tables={
		desc=' / ',
	},
}

```
## General options
* `name` - string: logfile name, like "A/FOO.CSV". Required.
* `append` - boolean: If true, name is appended to. Otherwise, it is overwritten each time `csvlog.new` is used.
* `dummy` - boolean: If true, no output file is created, and all log values are discarded
* `buffer_mode` - string: one of "os", "table" or "sync". Default is os.
   * "os" opens the file once in csvlog.new, uses write to write each line, and closes the file on `log:close`. This means the camera OS handles file buffering, and writes have relatively little impact on script performance. However, it also means that a script crash or error can result in losing a lot of log lines.
   * "table" stores all log values in a Lua table until `log:flush` or `log:close` is called, at which point, the log is opened, appended to and closed. This allows the script to manage writes, or avoid them entirely while the script is running, but a script that logs a lot can easily exhaust available memory.
   * "sync" opens the file, appends and closes for each `log:write` call. This minimizes information loss crashes, but can significantly impact script performance because of the many small writes and file flushes.
* `quote_mode` - string: one of "never", "auto", or "always". Defines how log values are quoted in the CSV. Default "auto". Format when quoted is generally consistent with [RFC 4180](https://datatracker.ietf.org/doc/html/rfc4180), except that newlines are unix-style LF rather than CRLF. Quotable characters are comma, double quote, CR and LF.
   * "never" no quoting is done. If the script puts quotable characters in values, the log will be not be a well formed CSV
   * "auto" log values are checked for quotable characters, and any fields that contain them are quoted.
   * "always" log values are always quoted.

## Defining columns
Column names and order are defined using the `cols` option, which must be an array of strings and/or arrays. At least one column must be defined. Strings define column names, in the order they appear. Arrays are processed recursively, allowing script modules to define a set of columns which they expect to log to. Column names must be unique.
### Function columns
Function columns have their values set by a function called automatically when log:write() is called. They are defined in the `funcs` option, which is a table mapping column names to functions. Any columns referenced in `funcs` must also appear in `cols`. If a function requires arguments, it can be wrapped as `tsensor` is in the example above.
### Table columns
Table columns accumulate values each time `log:set` is called, and concatenate them with a separator on `log:write`. This can be used in conjunction with `log:text_logger` to record free-form text messages.
## Setting column values
Values are normally set using `log:set`, which takes Lua table of column name, value pairs, like
```lua
log:set{
	foo="bar",
	tv=get_tv96(),
	av=get_av96(),
}
```
## Logging free-form text
It is frequently desirable to record free-form text message for debugging or flagging conditions that don't conveniently map to CSV cells. This is supported using the `log:text_logger` function, which returns a function which appends `string.format` formatted text to a specified table column each time it is called. For example
```lua
logdesc=log:text_logger('desc')
logdesc('started %s',os.date())
```
creates the function `logdesc` which logs to the column `desc`, and then writes a message with the current date to it.
## Logging time intervals
The function `log:dt_logger` can be used to create functions which measure elapsed time in milliseconds within a given log row. `log:dt_logger` takes the name of a column to use as the start time (typically, the start of a loop iteration) and returns a function which when called, sets a named column to the difference between the current tick time and the start time. For example
```lua
-- initialization
logtime=log:dt_logger('start')
-- ... main loop
log:set{start=get_tick_count()} -- set the start column value
-- ... stuff
logtime('stage1') -- log time between start and stage one into column stage1
-- ... more stuff
logtime('stage2') -- log time between start and stage two into column stage2

```
## Other functions
* `log:close` should be called when the script ends, to ensure the log is fully written to file. No further writes are possible after close is called. To ensure output is written without closing, use `log:flush`.
* `log:flush` may be called to ensure the most recent values written with `log:write` are written to SD card. The effect depends on the buffer mode: For "os", Lua `file:flush` is called. For "table", the file is opened, all pending lines are written, and the file is closed. For "sync", `log:flush` has no effect, since each row is automatically flushed.


## Examples
See [rawopint](/src/rawopint), [fixedint](/src/fixedint) and [contae](/src/contae) in this repository.
