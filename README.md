# Overview
This is a tool to solve the problem of needing to compile for specific targets. It creates a shell script which, when run, will create the original code, compile it, then remove the uncompiled code, leaving only the binary and the shell script.
# Settings
There are some settings to change how the shell script or its data get created. All the fields and the file itself are optional and the order of the fields doesn't matter.
### 1. optimize
This takes a boolean for whether or not the binary should be optimized. The default is true and the value should not be in quotation marks.
### 2. bin_name
This changes the name of the outputed binary and takes a string. By default it will use the name of the project as defined in Cargo.toml
### 3. shell_name
This changes the name of the shell script and takes a string. By default it will use the name of the project as defined in Cargo.toml
### Example:
```toml
optimize = false
bin_name = "foo"
shell_name = "bar"
```
All of the fileds are individually optional, so the file can be completely empty and still be valid. The file itself is also completely optional.
