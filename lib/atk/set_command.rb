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
        exec_path = "C:\\Users\\#{username}\\AppData\\local\\Microsoft\\WindowsApps\\#{name}.exe"
        local_place = HOME/"atk"/"temp"/name+".rb"
        # 
        # create an exe file
        # 
        IO.write(local_place, code)
        system("orca", local_place ,"--no-dep-run")
        temp_exe_file = local_place.gsub(/\.rb$/, "") + ".exe"
        FileUtils.move(temp_exe_file, exec_path)
    end
end
