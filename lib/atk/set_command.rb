require 'method_source'
require_relative './extra_file_utils'
require_relative './os'

def set_command(name, code)
    if OS.is?("unix")
        exec_path = "/usr/local/bin/#{name}"
        local_place = HOME/"atk"/"temp"/name
        # create temp if it doesn't exist
        FileUtils.makedirs(File.dirname(local_place))
        # create the file
        IO.write(local_place, "#!/usr/bin/ruby\n"+code)
        # copy to command folder
        system("sudo", "cp", local_place, exec_path)
        system("sudo", "chmod", "o+x", exec_path)
    elsif OS.is?("windows")
        username = `powershell -command "echo $env:UserName"`.chomp
        exec_path = "C:\\Users\\#{username}\\AppData\\local\\Microsoft\\WindowsApps\\#{name}"
        IO.write(exec_path, "#!/usr/bin/ruby\n"+code)
    end
end
