require_relative './file_system'
require_relative './console'
require_relative './info'
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
            when 'gem'
                gem_path = AtkPaths["ruby"].sub(/\/ruby$/,"\/gem")
                if FS.file?(gem_path)
                    return gem_path
                end
                # FUTURE: this should eventually have better error handling
                return OS.path_for_executable("gem")
            when 'repos'
                return HOME/"atk"/"repos"
            when 'commands'
                if OS.is?("unix")
                    return "/usr/local/bin"
                else
                    return "C:\\Users\\#{FS.username}\\AppData\\local\\Microsoft\\WindowsApps"
                end
        end
    end
end

module Atk
    @@atk_settings_key = "atk_settings"
    def self.version
        require_relative '../atk_toolbox/version.rb'
        require_relative './version.rb'
        return Version.new(AtkToolbox::VERSION)
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
    
    def self.checkup
        errors = {}
        
        # make sure ruby is the corrct version
        if VERSION_OF_RUBY >= Version.new("2.6.0")
            errors[:ruby_version_too_high] = true
        elsif VERSION_OF_RUBY < Version.new("2.5")
            errors[:ruby_version_too_low] = true
        end
        
        # make sure git is installed and up to date
        if not Console.has_command("git")
            errors[:doesnt_have_git] = true
        else
            git_version = Version.extract_from(`git --version`)
            if git_version < Version.new("2.17")
                errors[:git_version_too_low] = true
            end
        end
        
        # FUTURE: checkup on the package manager
        
        # FUTURE: verify that windows and unix paths are highest priority
        
        if OS.is?("unix")
            sources = Console.command_sources()
            top_source = sources[0]
            path_for_commands = Atk.paths[:commands]
            if top_source != path_for_commands
                errors[:commands_are_not_at_top_of_path] = true
                if not sources.any?{ |each| each == path_for_commands }
                    errors[:commands_are_not_in_path] = true
                end
            end
        end
        
        # 
        # TODO: talk about any found errors
        # 
        if errors.include?[:ruby_version_too_high]
            puts "It looks like your ruby version is too high for ATK"
            puts "some parts of ATK might still work, however expect it to be broken"
        end
    end
    
    def self.setup(package_name, arguments)
        repo_url = AtkPackage.new(package_name).url
        project_folder = Atk.info["project_folder"]
        # if there's no project folder
        if not project_folder
            # then use the current folder
            project_folder = FS.pwd
            puts "Project will be downloaded to #{project_folder.to_s.color_as :key_term}"
            puts "(your current directory)"
            puts ""
        end
        project_name = Console.ask("What do you want to name the project?")
        project_path = project_folder/project_name
        Git.ensure_cloned_and_up_to_date(project_path, repo_url)
        FS.in_dir(project_path) do
            setup_command = Info.commands['(setup)']
            if setup_command.is_a?(Code) || setup_command.is_a?(String)
                puts "\n\n#{"Running (setup) command:".color_as :title}\n"
                sleep 1
                if setup_command.is_a?(Code)
                    setup_command.run(arguments)
                else
                    system(setup_command + Console.make_arguments_appendable(arguments))
                end
            end
            puts "\n\n\n\n============================================================"
            puts "Finished running setup for: #{project_path.color_as :good}"
            puts "This project has these commands avalible:"
            system "project commands"
            puts "\ndon't forget to do:\n#{"cd '#{project_path}'".color_as :code}"
        end
    end
    
    def self.run(package_name, arguments=[])
        the_package = AtkPackage.new(package_name)
        the_package.run(arguments)
    end
    
    def self.not_yet_implemented()
        puts "Sorry, this feature is still under development"
    end
    
    def self.update(*args)
        # 
        # update a specific repo/package
        # 
        if args.size != 0
            Atk.not_yet_implemented()
            return
        end
        
        # 
        # update ATK itself
        #
        puts "Checking latest online version"
        console_output = IO.popen([Atk.paths['gem'], "list", "atk_toolbox", "--remote"]).read
        filtered = console_output.split("\n").select{|each| each =~ /^atk_toolbox \(/}
        latest_version = Version.extract_from(filtered[0])
        # if update avalible
        if Atk.version < latest_version
            puts "Newer version avalible, installing now"
            # install the new gem
            system(Atk.paths['gem'], "install", "atk_toolbox")
            # run the update handler
            temp_file = Atk.temp_path("after_gem_update.rb")
            FS.download("https://raw.githubusercontent.com/aggie-tool-kit/atk-toolbox/master/lib/after_gem_update.rb", to: temp_file)
            system(Atk.paths["ruby"], temp_file, Atk.version.to_s)
        else
            puts "System up to date"
        end
    end
end
ATK = Atk

class AtkPackage
    def initialize(package_name)
        @init_name = package_name
        @package_info_loaded = false
        @dont_exist = {}
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
            # if the package name does not have a slash in it, then assume it is a core / approved package
            if not (simple_name =~ /.*\/.*/) 
                raise "That package #{@init_name} doesn't seem to be a core package"
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
            puts "self.cache_location is: #{self.cache_location} "
            puts "self.url is: #{self.url} "
            Git.ensure_cloned_and_up_to_date(self.cache_location, self.url)
            @is_cached = true
        end
    end
    
    # 
    # parse package
    #     
    def ensure_package_info()
        if not @package_info_loaded
            @package_info_loaded = true
            self.ensure_cached()
            FS.in_dir(self.cache_location) do
                if not FS.file?("./info.yaml")
                    @dont_exist[:yaml_file] = true
                end
                begin
                    # must be in top most dir
                    @info = YAML.load_file("./info.yaml")
                rescue => exception
                    @dont_exist[:correctly_formatted_yaml_file] = true
                end
                
                # attempt to load a version
                begin
                    version = Version.new(@info['(using_atk_version)'])
                rescue => exception
                    version = nil
                    @dont_exist[:using_atk_version] = true
                end
                # if there is a version
                if version.is_a?(Version)
                    # if the version is really old
                    if version <= Version.new("1.0.0")
                        raise <<-HEREDOC.remove_indent
                            
                            
                            It appears that the #{self.simple_name()} package is using
                            the alpha version of ATK (1.0.0), which is no longer supported.
                            This is probably just a simple versioning mistake.
                            Please ask the maintainer of the #{self.simple_name()} package to
                            update it to a newer ATK package format
                        HEREDOC
                    elsif version <= Version.new("1.1.0")
                        self.parser_version_1_1(@info)
                    else
                        raise <<-HEREDOC.remove_indent
                            
                            
                            The package #{self.simple_name()} has a (using_atk_version)
                            that is newer than the currently installed ATK can handle:
                            version: #{version}
                            
                            This means either
                                1. ATK needs to be updated (which you can do with #{'atk update'.color_as :code})
                                2. The package has specified a version of ATK that doesn't exist
                        HEREDOC
                    end  
                end
            end
        end
    end
    
    # 
    # (using_atk_version) 1.1.0
    # 
    # (package):
    #     (actions):
    #          (run): *run command as string*
    def parser_version_1_1(info)
        # 
        # inits:
        #    @package_info: nil
        #    @actions: {}
        #    @run: nil
        # 
        if @info.is_a?(Hash)
            @package_info = @info['(package)']
            if @package_info.is_a?(Hash)
                @actions = @package_info['(actions)']
            else 
                @dont_exist[:package_info] = true
            end
            if not @actions.is_a?(Hash)
                @actions = {}
                @dont_exist[:actions] = true
            end
            
            @run = @actions['(run)']
            if not @run.is_a?(String)
                @dont_exist[:run_action] = true
            end
        end
    end
    
    def run(arguments)
        self.ensure_package_info()
        # if it exists, run it
        if @run.is_a?(String)
            FS.in_dir(self.cache_location) do
                system(@run + Console.make_arguments_appendable(arguments))
                return $?.success?
            end
        # if not, explain why not
        else
            custom_message = <<-HEREDOC.remove_indent
            
                When trying 
                    to perform the #{"run".color_as :code} action
                    on the #{self.simple_name.to_s.color_as :key_term} module
                    with these arguments: #{arguments.inspect.to_s.color_as :argument}
                
                There was an issue because:
            HEREDOC
            
            # FUTURE: make a more standardized error reporting tool and it that here
            
            good = ->(message) do
                "    ✓ #{message.color_as :good}"
            end
            bad = ->(message) do
                "    ✖ #{message.color_as :bad}"
            end
            
            if @dont_exist[:yaml_file]
                custom_message += <<-HEREDOC.remove_indent
                    #{bad["there was no info.yaml for that package"]}
                    and an info.yaml is the location for defining a run action 
                    
                HEREDOC
            elsif @dont_exist[:correctly_formatted_yaml_file]
                custom_message += <<-HEREDOC.remove_indent
                    #{good["there was a info.yaml for that package"]}
                    #{bad["the info.yaml is not parseable"]}
                    and an info.yaml is the location for defining a run action
                    
                HEREDOC
            elsif @dont_exist[:using_atk_version]
                custom_message += <<-HEREDOC.remove_indent
                    #{good["there was a info.yaml for that package"]}
                    #{good["the info.yaml was parseable"]}
                    #{@dont_exist[:using_atk_version] && bad["the info.yaml didn't have a (using_atk_version) key"]}
                    #{@dont_exist[:package_info]      && bad["the info.yaml didn't have a (package_info) key"]}
                    #{@dont_exist[:actions]           && bad["the info.yaml didn't have a (package_info): (actions) key"]}
                    #{@dont_exist[:run_action]        && bad["the info.yaml didn't have a (package_info): (actions): (run) key"]}
                HEREDOC
            end
            
            raise <<-HEREDOC.remove_indent
                
                
                #{custom_message}
                
                This is almost certainly a problem with the package
                Please contact the maintainer of #{self.simple_name}
                and let them know about the above issue
            HEREDOC
        end
    end
end