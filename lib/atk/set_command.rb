require_relative './file_sys'
require_relative './os'
require_relative './atk_info'

# the reason this isn't inside of the console.rb
# is because atk_info requires console
# and this requires atk_info
# which would cause a circular dependency

# add set_command to the Console
class TTY::Prompt
    def set_command(name, code)
        if OS.is?("unix")
            exec_path = "/usr/local/bin/#{name}"
            local_place = ATK.temp_path(name)
            # add the hash bang
            hash_bang = "#!#{ATK.paths[:ruby]}\n"
            # create the file
            FS.write(hash_bang+code, to: local_place)
            # copy to command folder
            system("sudo", "cp", local_place, exec_path)
            system("sudo", "chmod", "ugo+x", exec_path)
        elsif OS.is?("windows")
            # check for invalid file paths, see https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file
            if name =~ /[><:"\/\\|?*]/
                puts "Sorry #{name} isn't a valid file path on windows"
                return ""
            end
            username = FS.username
            exec_path = "C:\\Users\\#{username}\\AppData\\local\\Microsoft\\WindowsApps\\#{name}"
            
            # create the code
            IO.write(exec_path+".rb", code)
            # create an executable to call the code
            IO.write(exec_path+".bat", "@echo off\nruby \"#{exec_path}.rb\" %*")
        end
    end
end