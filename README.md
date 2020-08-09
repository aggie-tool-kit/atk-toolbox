# What is the ATK Toolbox?
It is a ruby gem composed of tools that "just work". This library was created to make cross-platform automation effortless and reliable.

For example there are one-liners for:
- detecting operating system versions
<br><code>OS.is?('mac')</code>
- validating/asking for user input of various kinds
<br><code>Console.yes?('do you like automation?')</code>
- colorizing terminal output
<br><code>puts 'hello'.blue + ' world'.green</code>
- creating/deleting/compressing/downloading files
<br><code>FileSystem.download("https://bit.ly/2tCtP2h", to: HOME/'Downloads')</code>


# How do I install/use it?
First install ATK (a one-line installation) from here: https://github.com/aggie-tool-kit/atk

Installing ATK will automatically install Ruby and the atk_toolbox gem

At the top of any Ruby `.rb` file you can call <br>
`require 'atk_toolbox'` <br>
and then all of the toolbox examples below will be avalible to you.


# Where's the detailed documentation?
See the documentation.md file


# What side effects are added?

#### Cross-Platform File Paths
This uses the string-division operator
```ruby
downloads_path = HOME/"Downloads"
# >>> on Mac/Linux /usr/joe/Downloads
# >>> on Windows C:\Users\joe\Downloads
```

#### Cross-Platform Command Chaining
This uses the negative operator for strings to run a commandline command. It returns true/false based on the exit code of the process.
```ruby
using Atk
-"npm run bulid" && -"npm run serve" || -"npm run cleanup-error"
```

#### Indent-Adjusted Docstrings
```ruby
if condition
    puts <<-HEREDOC.remove_indent
        This message is not going to be indented
        Because of the remove indent
        
        Now multiline messages are easy
    HEREDOC
end
```

#### Colorization
```ruby
puts "hello world".blue
puts "warning".yellow
puts "error".white.on_red
puts "big error".red.bold.blink
puts "unknown".magenta
```

# What objects/classes are avalible? (Overview)
<table>
  <tr>
    <th>Object</th>
    <th>Examples</th>
  </tr>
  
  <!-- OS -->
  <tr>
  <td>OS</td>
  <td><br>

```ruby
OS.version
OS.is?('mac')
OS.is?('linux')
OS.is?('windows')
OS.is?('unix')
OS.is?('debian')
OS.is?('ubuntu')
```
  </td>
  </tr>
  
  <!-- Console -->
  <tr>
  <td>Console</td>
  <td><br>

```ruby
Console.has_command?(_name_of_executable_)
Console.require_superuser
Console.keypress("Press enter continue", keys: [:return])
Console.keypress("Press any key, resumes automatically in 3 seconds ...", timeout: 3)
Console.yes?('is Linux better than windows?')
Console.select("What is your favorite color?", [ "red", "blue", "green", "other" ])
Console.multi_select("What colors do you like?", [ "red", "blue", "green", "other" ])
Console.args
Console.stdin
```
  </td>
  </tr>
 
  <!-- FileSystem -->
  <tr>
  <td>FileSystem</td>
  <td><br>

```ruby
FileSystem.read(_filepath_)
FileSystem.write(_string_, to: _filepath_)
FileSystem.download(_url_, to: _filepath_)
FileSystem.delete(_file_or_folder_)
FileSystem.copy(from: _file_or_folder_, to: _folder_, new_name: _filename_)
FileSystem.move(from: _file_or_folder_, to: _folder_, new_name: _filename_)
FileSystem.rename(_file_or_folder_, new_name: _filename_)
FileSystem.exists?(_file_or_folder_)
FileSystem.file?(_file_or_folder_)
FileSystem.folder?(_file_or_folder_)
FileSystem.path_pieces(_file_or_folder_)
FileSystem.pwd
FileSystem.home
FileSystem.username
FileSystem.cd(_path_)
FileSystem.ls(_optional_path_)
FileSystem.list_files(_optional_path_)
FileSystem.list_folders(_optional_path_)
```
  </td>
  </tr>
  
  <!-- ATK -->
  <tr>
  <td>ATK</td>
  <td><br>

```ruby
ATK.version
ATK.setup(_repo_name_, _array_of_setup_arguments_)
ATK.run(_repo_name_, _array_of_run_arguments_)
```
  </td>
  </tr>
 
  <!-- Info -->
  <tr>
  <td>Info</td>
  <td><br>

```ruby
Info.commands
Info.paths
Info.folder
Info[ _yaml_key_ ]
```
  </td>
  </tr>
  
  
  <!-- Version -->
  <tr>
  <td>Version</td>
  <td><br>

```ruby  
Version.extract_from(_string_that_contains_version_somewhere_)
Version.new('1.2.3').major
Version.new('1.2.3').minor
Version.new('1.2.3').patch
Version.new('1.2.3.4.5').levels[4]
Version.new('1.2.3') <= Version.new('4.5.6')
```
  </td>
  </tr>
  
</table>