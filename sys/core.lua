return {
    version = "0.1.0",

    scripts = {
        build   = "build.lua",
        clear   = "clear.lua",
        compile = "compile.lua",
        combine = "combine.lua",
        execute = "execute.lua",
        deliver = "deliver.lua",
        prepare = "prepare.lua",
        refresh = "refresh.lua",
    },

    keys = {
        "pjpath::",
        "expath::",
        "desktop::",
        "release::",
        "optimize::",
        "warnings::",
        "compiler::",
        "language::",
        "standard::",
    },

    help = [[
---------------------------------------

PJMage - C/C++ Build System
Usage: mage <command> <value> key::"<value>"

---------------------------------------

    Build Commands:

build   <project name> --- Compile, Combine, and Execute the current project
compile <project name> --- Run the multi-threaded compiler (parse.lua)
combine <project name> --- Link object files into a binary (merge.lua)
execute <project name> --- Launch the project binary with mapped DLL paths (launch.lua)

---------------------------------------

    Project Commands:

clear   <project name> --- Clean object files and temporary build artifacts
prepare <project name> --- Initialize a new Mage project structure in the CWD
refresh <project name> --- Refresh current project data and junction links
deliver <project name> --- Export project into CWD/out/ or specified path

---------------------------------------

    Global Commands:

version --- Display current Mage version and system info
help    --- Display this help message

---------------------------------------

    Options:

pjpath    ---  Custom target directory               (default: CWD)
expath    ---  Custom export directory               (default: CWD/out)
desktop   ---  Custom target between console and GUI (default: console)
release   ---  Custom release/debug level            (default: debug)
optimize  ---  Custom optimization level             (default: none)
warnings  ---  Custom warnings level                 (default: strict)
language  ---  Custom project language               (default: C++)
standard  ---  Custom project standard               (default: C++20/C18)

---------------------------------------

    Examples:

mage build
mage compile "My Game" pjpath::"C:/Projects/MyGame"

---------------------------------------
]]
}