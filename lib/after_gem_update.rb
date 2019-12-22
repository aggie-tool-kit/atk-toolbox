require 'atk_toolbox'

# helper function
download_and_install_command = ->(command) do
    atk_command_download_path = Atk.temp_path("#{command}.rb")
    source = "https://raw.githubusercontent.com/aggie-tool-kit/atk-toolbox/master/custom_bin"
    FS.download("#{source}/#{command}" , to: atk_command_download_path)
    Console.set_command(command, FS.read(atk_command_download_path))
end

#
# overwrite the commands
# 
download_and_install_command["atk"]
download_and_install_command["project"]
download_and_install_command["_"]

# 
# print success
# 
puts ""
puts ""
puts ""
puts "=============================="
puts "        ATK installed "
puts "=============================="