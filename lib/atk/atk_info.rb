require_relative './file_sys'
require_relative './console'
require_relative './yaml_info_parser'
require_relative './os'
require_relative './git'
require 'yaml'

class AtkPaths
    def self.[](name)
        # convert symbols to strings
        name = name.to_s
        case name
            when 'atk'
                return HOME/"atk"
            when 'temp'
                return self['atk']/"temp"
            when 'info'
                return HOME/"info.yaml"
            when 'ruby'
                atk_path_settings = ATK.info["paths"]
                if atk_path_settings.is_a?(Hash) and atk_path_settings["ruby"].is_a?(String)
                    ruby_path = atk_path_settings["ruby"]
                elsif OS.is?(:mac)
                    if `which rbenv`.chomp.size > 0
                        ruby_path = `rbenv which ruby`.chomp
                    else
                        ruby_path = "/usr/bin/ruby"
                    end
                elsif OS.is?(:unix)
                    ruby_path = "/usr/bin/ruby"
                else
                    ruby_path = OS.path_for_executable("ruby")
                end
                return ruby_path
            when 'core_yaml'
                return HOME/"atk"/"core.yaml"
            when 'installed_yaml'
                return HOME/"atk"/"installers.yaml"
            when 'installers_folder'
                return HOME/"atk"/"installers"
        end
    end
end

module ATK
    @@atk_settings_key = "atk_settings"
    def self.paths
        return AtkPaths
    end
    
    def self.temp_path(filename)
        new_path = ATK.paths[:temp]/filename
        # make sure the path is empty
        FS.write("", to: new_path)
        FS.delete(new_path)
        return new_path
    end
    
    def self.info
        settings_path = ATK.paths[:info]
        # if it doesn't exist then create it
        if not FS.exist?(settings_path)
            FS.write("#{@@atk_settings_key}: {}", to: settings_path)
            return {}
        else
            data = YAML.load_file(settings_path)
            if data.is_a?(Hash)
                if data[@@atk_settings_key].is_a?(Hash)
                    return data[@@atk_settings_key]
                end
            else
                return {}
            end
        end
    end
    
    def self.save_info(new_hash)
        settings_path = ATK.paths[:info]
        current_settings = ATK.info
        updated_settings = current_settings.merge(new_hash)
        
        info_data = YAML.load_file(ATK.paths[:info])
        if info_file.is_a?(Hash)
            info_data[@@atk_settings_key] = updated_settings
        else
            info_data = { @@atk_settings_key => updated_settings }
        end
        
        FS.save(info_data, to: ATK.paths[:info], as: :yaml )
    end
    
    def self.simplify_package_name(source)
        source = source.strip
        # if its starts with "atk/", just remove that part
        source = source.sub( /^atk\//, "" )
        # if it starts with "https://github.com/", just remove that part
        source = source.sub( /^https:\/\/github.com\//, "" )
        return source
    end
    
    def self.package_name_to_url(package_name)
        # if its starts with "atk/", just remove that part
        package_name = ATK.simplify_package_name(package_name)
        # if the package name does not have a slash in it, then assume it is a core / approved installer
        if not (package_name =~ /.*\/.*/) 
            # TODO: turn this into a check for is_core_repo?(package_name)
            # path_to_core_listing = ATK.paths[:core_yaml]
            # core = YAML.load_file(path_to_core_listing)
            # if core[package_name] == nil
            #     puts "I don't see that package in the core, let me make sure I have the latest info"
            #     download("https://raw.githubusercontent.com/aggie-tool-kit/atk/master/interface/core.yaml", as: path_to_core_listing)
            #     core = YAML.load_file(path_to_core_listing)
            # end
            # if core[package_name] != nil
            #     repo_url = core[package_name]["source"]
            # else
                raise "That package doesn't seem to be a core package"
            # end
         # if it does have a slash, and isn't a full url, then assume its a github repo
        elsif not package_name.start_with?(/https?:\/\//)
            repo_url = "https://github.com/"+package_name
        else
            repo_url = package_name
        end
        return repo_url
    end
    
    def self.setup(package_name, arguments)
        repo_url = ATK.package_name_to_url(package_name)
        project_folder = ATK.info["project_folder"]
        # if there's no project folder
        if not project_folder
            # then use the current folder
            project_folder = FS.pwd
            puts "Project will be downloaded to #{project_folder.to_s.yellow}"
            puts "(your current directory)"
            puts ""
        end
        project_name = Console.ask("What do you want to name the project?")
        project_path = project_folder/project_name
        Git.ensure_cloned_and_up_to_date(project_path, repo_url)
        FS.in_dir(project_path) do
            setup_command = Info.project_commands['(setup)']
            if setup_command.is_a?(Code) || setup_command.is_a?(String)
                puts "\n\nRunning (setup) command:\n".green
                sleep 1
                if setup_command.is_a?(Code)
                    setup_command.run(arguments)
                else
                    safe_arguments = arguments.map do |each|
                        "'"+Console.single_quote_escape(each)+"'"
                    end
                    console_line = setup_command+' '+(safe_arguments.join(' '))
                    system(console_line)
                end
            end
            puts "\n\n\n\n============================================================"
            puts "Finished running setup for: #{project_path.green}"
            puts "This project has these commands avalible:"
            system "project commands"
            puts "\ndon't forget to do:\n#{"cd '#{project_path}'".blue}"
        end
    end
end