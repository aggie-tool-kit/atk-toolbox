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
                atk_path_settings = Atk.info["paths"]
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
            when 'repos'
                return HOME/"atk"/"repos"
        end
    end
end

module Atk
    @@atk_settings_key = "atk_settings"
    def self.version
        require_relative '../atk_toolbox/version.rb'
        return AtkToolbox::VERSION
    end
    
    def self.paths
        return AtkPaths
    end
    
    def self.temp_path(filename)
        new_path = Atk.paths[:temp]/filename
        # make sure the path is empty
        FS.write("", to: new_path)
        FS.delete(new_path)
        return new_path
    end
    
    def self.info
        settings_path = Atk.paths[:info]
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
            end
        end
        return {}
    end
    
    def self.save_info(new_hash)
        settings_path = Atk.paths[:info]
        current_settings = Atk.info
        updated_settings = current_settings.merge(new_hash)
        
        info_data = YAML.load_file(Atk.paths[:info])
        if info_file.is_a?(Hash)
            info_data[@@atk_settings_key] = updated_settings
        else
            info_data = { @@atk_settings_key => updated_settings }
        end
        
        FS.save(info_data, to: Atk.paths[:info], as: :yaml )
    end
    
    def self.setup(package_name, arguments)
        repo_url = AtkPackage.new(package_name).url
        project_folder = Atk.info["project_folder"]
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
            setup_command = Info.commands['(setup)']
            if setup_command.is_a?(Code) || setup_command.is_a?(String)
                puts "\n\nRunning (setup) command:\n".green
                sleep 1
                if setup_command.is_a?(Code)
                    setup_command.run(arguments)
                else
                    system(setup_command + Console.make_arguments_appendable(arguments))
                end
            end
            puts "\n\n\n\n============================================================"
            puts "Finished running setup for: #{project_path.green}"
            puts "This project has these commands avalible:"
            system "project commands"
            puts "\ndon't forget to do:\n#{"cd '#{project_path}'".blue}"
        end
    end
    
    def self.run(package_name, arguments=[])
        the_package = AtkPackage.new(package_name)
        the_package.run(arguments)
    end
    
    def self.not_yet_implemented()
        puts "Sorry, this feature is still under development"
    end
    
    def self.install(*args)
        if args.size == 0
            # 
            # create the file structure if it doesnt exist
            # 
            FS.makedirs(HOME/"atk"/"installers")
            # download the files
            if not FS.exist?(HOME/"atk"/"core.yaml")
                FS.download('https://raw.githubusercontent.com/aggie-tool-kit/atk/master/core.yaml'       , to: HOME/"atk"/"core.yaml")
            end
            if not FS.exist?(HOME/"atk"/"installers.yaml")
                FS.download('https://raw.githubusercontent.com/aggie-tool-kit/atk/master/installers.yaml' , to: HOME/"atk"/"installers.yaml")
            end

            #
            # overwrite the commands
            # 

            # atk
            atk_command_download_path = Atk.temp_path("atk.rb")
            FS.download('https://raw.githubusercontent.com/aggie-tool-kit/atk/master/atk'     , to: atk_command_download_path)
            Console.set_command("atk", FS.read(atk_command_download_path))

            # project
            project_command_download_path = Atk.temp_path("project.rb")
            FS.download('https://raw.githubusercontent.com/aggie-tool-kit/atk/master/project' , to: project_command_download_path)
            Console.set_command("project", FS.read(project_command_download_path))

            # the project run alias
            local_command_download_path = Atk.temp_path("local_command.rb")
            FS.download('https://raw.githubusercontent.com/aggie-tool-kit/atk/master/_'      , to: local_command_download_path)
            Console.set_command("_", FS.read(local_command_download_path))

            # 
            # print success
            # 
            puts ""
            puts ""
            puts ""
            puts "=============================="
            puts "        ATK installed "
            puts "=============================="
        else
            Atk.not_yet_implemented()
        end
    end
end



class AtkPackage
    def initialize(package_name)
        @init_name = package_name
    end
    
    def simple_name
        if @simple_name == nil
            source = @init_name.strip
            # if its starts with "atk/", just remove that part
            source = source.sub( /^atk\//, "" )
            # if it starts with "https://github.com/", just remove that part
            @simple_name = source.sub( /^https:\/\/github.com\//, "" )
        end
        return @simple_name
    end
    
    def url
        if @url == nil
            simple_name = self.simple_name()
            # if the package name does not have a slash in it, then assume it is a core / approved installer
            if not (simple_name =~ /.*\/.*/) 
                # TODO: turn this into a check for is_core_repo?(package_name)
                # path_to_core_listing = Atk.paths[:core_yaml]
                # core = YAML.load_file(path_to_core_listing)
                # if core[package_name] == nil
                #     puts "I don't see that package in the core, let me make sure I have the latest info"
                #     download("https://raw.githubusercontent.com/aggie-tool-kit/atk/master/interface/core.yaml", as: path_to_core_listing)
                #     core = YAML.load_file(path_to_core_listing)
                # end
                # if core[package_name] != nil
                #     repo_url = core[package_name]["source"]
                # else
                    raise "That package #{@init_name} doesn't seem to be a core package"
                # end
            # if it does have a slash, and isn't a full url, then assume its a github repo
            elsif not simple_name.start_with?(/https?:\/\//)
                repo_url = "https://github.com/"+simple_name
            else
                repo_url = simple_name
            end
            @url = repo_url
        end
        return @url
    end
    
    def cache_name()
        if @cache_name == nil
            repo_url = self.url()
            require 'digest'
            repo_hash = Digest::MD5.hexdigest(repo_url)
            repo_name = Git.repo_name(repo_url)
            @cache_name = repo_name+"_"+repo_hash
        end
        return @cache_name
    end
    
    def cache_location()
        if @cache_location == nil
            @cache_location = Atk.paths['repos']/self.cache_name
        end
        return @cache_location
    end
    
    def ensure_cached()
        if @is_cached == nil
            Git.ensure_cloned_and_up_to_date(self.cache_location, self.url)
            @is_cached = true
        end
    end
    
    def run(arguments)
        # make sure the repo is downloaded
        self.ensure_cached()
        FS.in_dir(self.cache_location) do
            run_command = nil
            begin
                run_command = Info["(installer)"]["(commands)"]["(run)"]
            rescue
            end
            if run_command.is_a?(String)
                system(run_command + Console.make_arguments_appendable(arguments))
            else
                # 
                # refine the error message
                # 
                custom_message = ""
                if run_command != nil && ( !run_command.is_a?(String) )
                    custom_message = "✖ the (run) command wasn't a string".red
                else
                    yaml_exists = File.exist?(self.cache_location()/"info.yaml")
                    
                    if not yaml_exists
                        custom_message = "✖ there was no info.yaml for this package".red
                    else
                        error_loading_yaml = false
                        begin
                            YAML.load_file("./info.yaml")
                        rescue
                            error_loading_yaml = true
                        end
                        if error_loading_yaml
                            custom_message = "✖ there was an issue loading the info.yaml for this package".red
                        else
                            if run_command == nil
                                custom_message = "✖ there wasn't an (installer) key with a run command".red
                            end
                        end
                    end
                end
                
                # throw error for command not being runable
                raise <<-HEREDOC.remove_indent
                    
                    
                    #{custom_message}
                    
                    For the repository to be runnable
                    1. There needs to be an #{"info.yaml".blue}
                    2. The info.yaml needs to be in the root directory/folder
                    3. It needs to contain:
                    #{"
                    (installer):
                        (commands):
                            (run): \"a commandline command\"
                    ".blue}
                HEREDOC
            end
        end
    end
end