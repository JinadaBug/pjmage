# pjmage
PJMage - easy C/C++ build/export system
---------------------------------------------------------------------
Installation logic:

During PJMage installer (We will have Windows, Linux and macOS installers)
- Install the correct compiler (OS dependent)
- Extracts PJMage files into proper location
- Add mage.exe to the PATH
- Give it the path to the compiler binaries or whatever is important
---------------------------------------------------------------------
Commands:

mage version
// Will tell the current mage version, like mage 0.1.0 beta or something

mage refresh
// Checks for available packages and resfreshes the local registry (if there will be such)

mage install package::"package ID/Name" version::"package version (optional)"
// Will install package onto the machine with the specified version if listed, or latest by default

mage create project::"project name" path::"project/path (optional)" lang::"project language (optional)"
// It will use path the PJMage is launched in as the project path root by default
// Default language is C++, the standard is latest supported across the systems, but it will be possible to manually set in project.lua manifest
// The compiler is installed during PJMage installation (MSVC on Windows, GCC/G++ on Linux, Clang on macOS)

mage delete project::"project name"
// Yes, it will wipe off the whole project folders, though the prompt will appear, asking to type project name in and hit enter

mage compile project::"project name"
// Compile the project (smartly) but don't run it

mage execute project::"project name"
// Run the project without compilation

mage build project::"project name"
// Compile & Execute the project

mage export project::"project name" folder::"output folder"
// Exports .exe and recquired .dll's into the dedicated folder

the idea is that inc, lib, dll, bin, bat and obj folders all move inside mage folder
as a result, you can have your own folder anywhere (as long as you properly inititalized it via mage create)
and it will look absolutely simple (just hpp/cpp file)

---------------------------------------------------------------------
Under the hood:

mage folder:
    -- inc: // all include
        -- SDL3: // sdl includes for example
        -- Vulkan: // Vulkan includes
        -- ASIO: // ASIO standalone includes
        -- D3DX12: // D3DX12 Includes and etc etc etc
        ...
    -- lib: // all libraries
        -- lua-5.5.0.lib
        ...
    -- dll: // all dll files
        ...
    -- obj: // all obj files (per project name)
        -- project_1:
            ...
    -- bin: // all binaries (per project name)
        -- project_1:
            ...
    -- bat: // all build scripts (per project name)
        -- project_1:
    -- manifests:
        -- packages: // all package_1.lua files here
            ...
        -- projects: // all project_1.lua files here
            ...
        -- package_list.lua // all available packages
        -- project_list.lua // all available projects
