# pjmage
PJMage - easy C/C++ build/export system
---------------------------------------------------------------------
Installation logic:

During PJMage installer (We will have Windows, Linux and macOS installers)
- Install the correct compiler (OS dependent)
- Extracts PJMage files into proper location
- Add mage.exe to the PATH
- Give it the path to the compiler binaries or whatever is important
<br/><br/>

## Commands:
1. Help Command
```
mage help
```
Will tell the list of all available commands
<br/><br/>

2. Version Check
```
mage version
```
Will tell the current mage version, like mage 0.1.0 beta or something
<br/><br/>

3. Create project
```
mage prepare "project name"
```
It will use path the PJMage is launched in as the project path root by default, if you specify the name it will create the subfolder inside the current working directory
<br/>
Default language is C++, the standard is latest supported across the systems, but it will be possible to manually set in project.lua manifest
<br/><br/>

3. Compile project
```
mage compile "project name"
```
Compile the project (smartly) but don't run it
<br/><br/>

4. Link project
```
mage combine "project name"
```
Link the project. No execution
<br/><br/>

5. Execute project
```
mage execute "Project name"
```
Run the project without compilation
<br/><br/>

6. Build project
```
mage build "project name"
```
Compile & Execute the project
<br/><br/>

7. Export project
```
mage export "project name"
```
Exports .exe and recquired .dll's into the dedicated folder or CWD/out by default
<br/><br/>