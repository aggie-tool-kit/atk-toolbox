### Current Plan

- clean up structure
  - move the stager to the main repo
  - remove FIXME's
  - add comments
  - consider removing git object
  - add documentation
    - Features
      - File Handling
      - System Info
        - Username
        - OS
        - Version
      - Project Info
        - Info
      - User interactions
        - Colors
        - Heredoc
        - Console questions  

- improve the mac installer: add support for zsh and catalina

- remove .info_language_runner_cache as first step of script

- update the python installer
  - add interface for python version management
  - add a verification tool
  - have it provide an error message upon switching to python27 from python3 on windows
  - have it use pyenv for version management on mac/linux

- atk new project from
  - clones down the repo
  - deletes the git
  - runs git init
  - ask if want to connect it upstream

- create videos for
  - installing ATK
  - using ATK on a project
  - creating an ATK module
  - contributing to ATK toolbox

# Saftey fixes
- check the help commands in powershell

- fix the windows press-enter hangup
  - test it out through a non-console process like electron

- add background colors to all colored text

- have the update command perform saftey checks
  - windows version && macOS version
  - check ruby version
  - send an error message to the user if the bin is not at the top
  - explain how to fix it and set it to be at the top
  - have the update command perform saftey checks

- change the windows setup
  - create a highest_priority_commands folder
  - add the folder to the path ENV (potencially admin needed)
  - use this: ensure_in_path from: https://github.com/lukesampson/scoop/blob/08af9ff6e7f7b017701c0c9114294b13e1e83fb8/lib/core.ps1

- stablize the versioning of ruby and gem, and fix all path calls to them

# end Saftey fixes

- create a app
  - check if atk is installed, if not, ask to install it (just spit out the output)
  - new project button
    - ask where to save it
  - list out known projects based on info.yaml
  - on open, ask what app to open it with
  - recommend installing VS Code

- create an tamu-engr-111_2020 installer
  - installs and switches to python 3.6
  - installs numpy, matplotlib
  - downloads VS Code
  - installs the python extension
  - installs the material theme
  - installs code runner

- make the run command faster on windows

- create templates for websites, C++, python, and ruby

- create force push force pull on `project`

- add support for installing sub dependencies
  - create hashes of package.json, requirements.txt, gemfile, and the atk-dependencies
  - any time the hashes change, try to run their respective install commands
  - check the versions of the atk-dependencies
- maybe create downloadable info.yaml templates
- allow the commands key to be a script
- add hooks into the project commands
- allow ENV variables to be set in the info.yaml

### ATK toolbox
- create a standardized framework for good errors
    - where did the error happen (context)
    - why did the error happen (met/unmet requirements)
    - why are the unmet requirements needed
    - what to do (how to fix)
- create a colorization framework
    - package name
    - command name
    - command argument
    - system command
    - unimportant
    - bad
    - good
    - example
    - optional
- create a standardized console-command function
    - allow shell expansion
    - allow TTY emultation
    - allow raise error on nonzero exit code
    - allow providing an ENV
    - input/output
        - non-blocking
            - attach onstderr, onstdout
            - return OBJ with writeable stdout and pid
        - blocking
            - no user output, and return OBJ with stdout, stderr, out (combined), success
            - give full user output, return success
            - give full user output, and return OBJ with stdout, stderr, out (combined), success
            - allow setting streams for STDOUT, STDERR
- create tool for adding content to the bash profile/zsh profile/powershell profile


### Major
- rework the install system: have it based on binary names and version checking
- create the system for a bash-profile overwriter
  - startup scripts
  - ENV variables
  - PATH additions
  - alias commands
- create the atk_toolbox for javascript
- create the atk_toolbox for python
- create a YAML editor



### Old objectives
- create a versioning system for atk
- create a seperate organization for atk-core
- create a package
- test install the package on all OS's
- create a atk package template


- get the basic installers working
- add uninstall support
- get setup working for ubuntu
- create an API for registering a new global command
    - create a github installer template for creating a new global command
- add support for dynamic/version-specific dependencies
- add support for no-info.yaml package installers
- try downloading only the info.yaml first, and then check to see what else should be downloaded


- finish defining the package specs
    - create a github template for an installer
        - info.yaml # for project management commands
        - install
        - uninstall
- create an environment variable ATK that is a JSON object
    - have it contain all the info in the settings.yaml file
- create a way to set the ATK-installer-version variable
- create a way to keep a stack-frame-like recorder of the direct dependencies of an installer
- create the installer command that
    - check the version of the downloaded installer (which probably wont exist)
    - download the info.yaml of the remote installer, and check its installer version
    - if the installer version is newer, then download the whole repo
    - otherwise just use the downloaded installer
    - calls the atk_toolbox installer frame
    - downloads the info.yaml if there is one
        - checks the atk version
        - run the parser on the (installer):
        - this is the "standard installer key procedure":
            - if it is in the info.yaml
                - if it is a string, assume its !language/console
                - if it is !language/console then run it
                - if it is !language/ruby then run it
            - if its not in the yaml
                - try to download a file with that keyname + .rb and then run that
    - if there is no verison specified, then get the (latest_version)
        - if it is in info.yaml and it is a valid version (dot seperated numbers)
            - use that version
        - otherwise use the standard procedure
    - if the installed version is the same as the requested/latest
        - TODO: if this is a top-level call, ask if they'ed like to reinstall
        - if this is a recursive call, do nothing (finish)
    - if the requested version is older than then current one
        - if this is a recursive call
        - tell the user that a library asked for an older version but that its probably okay to use a newer one, and then ask if they'ed like to use the newer one
    - get the (dependencies)
        - if it is in info.yaml and it is a dict
            - then use that
        - otherwise follow standard prodecure for getting it
    - check the $DEPENDENCIES atk environment variable
        - if they're not on the pending set (which is a safety check for recursive dependencies) 
            - then recursively install them
    - for (on_install) follow standard prodecure
    - after install, remove the name from the pending set
    - pop the atk_toolbox installer frame to get a list of all the direct dependencies
    - add the installed version and its direct dependencies to `library.yaml`

- allow the commands key to be a script
- create an API for unzip/untaring a folder

### Pre-Alpha v2 Version
- Be able to parse the info.yaml
    - figure out how to modify the info.yaml without screwing up the *keys
- toolbox 
    - get the package manager class/obj working for windows and linux for
        - install
        - uninstall
- atk-setup
    - Create a one liner for windows and linux (that does nothing)
    - Get the base dependencies installed on ubuntu (with the one-liner)
    - Get the system commands into ubuntu path (with the one-liner)
- user interface
    - Be able to run the `project run __` command and it work on ubuntu

### Pre-Alpha v3 Version
- atk-setup
    - Get the base dependencies working on windows
    - Get the system commands into windows
- user interface
    - Be able to run the `project run __` command and it work on windows

### Alpha Backlog
- Get the basics of the install command working
- Agree on the info.yaml for the home folder
- Create a small dummy installer for part of the core repo


### Beta Backlog
- Get a basics of a npm or pip package manager working
- Create a tool for printing output
- Create a tool for asking users questions


### Full Release Backlog
- Parsing info.yaml
    - generate a list of evironment variables
- Get setting ENV variables locally working
- Create tool for adding global aliases 
- Create tool for adding global ENV variables on linux/mac for bash only 
- Get the autocomplete of the !language/console working

### Version 2 Backlog
- Create tool for adding global ENV variables on linux/mac for zsh
- Create an uninstaller for ATK
- Get structures working
    - generate a list of structures and their version #'s

### unsorted
- create a javascript and python API of atk_toolkit 
- standardize the ruby version that is used on mac and linux
- figure out how to run a version.rb script without it modifying anything






### Done
- remove the mac/windows/linux option from the info.yaml, do it with ruby instead
- move everything inside of the ruby gem repo
- change the update command to simply update the ruby gem, download/run a script, and
- do version checking for 1.0