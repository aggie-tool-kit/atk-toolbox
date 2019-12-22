require "yaml"
require "colorize"
require 'fileutils'
require_relative './os'
require_relative './remove_indent.rb'
require_relative './version.rb'


# 
# yaml format
# 
    # (using_atk_version)
    # (project)
        # (commands)
        # (paths)

# duplicated for the sake of efficieny (so that the parser doesn't need to import all of FileSystem)
module FileSystem
    def self.join(*args)
        if OS.is?("windows")
            folders_without_leading_or_trailing_slashes = args.map do |each|
                # replace all forward slashes with backslashes
                backslashed_only = each.gsub(/\//,"\\")
                # remove leading/trailing backslashes
                backslashed_only.gsub(/(^\\|^\/|\\$|\/$)/,"")
            end
            # join all of them with backslashes
            folders_without_leading_or_trailing_slashes.join("\\")
        else
            File.join(*args)
        end
    end
end

# TODO: for efficiency, have the parser generate a parsed object, instead of only handling everything dynamically (allow for both)

# 
# Create loaders for ruby code literal and console code literal
# 
    def register_tag(tag_name, class_value)
        YAML.add_tag(tag_name, class_value)
        Code.tags[tag_name] = class_value
    end
    class Code
        @@tags = {}
        def self.tags
            return @@tags
        end
        
        def init_with(coder)
            @value = coder.scalar
        end
        
        def run
            # TODO: improve this error message
            raise "This needs to be overloaded"
        end
        
        def to_s
            return @value
        end
    end
    
    # 
    # Ruby Code/Evaluation
    # 
    class RubyCode < Code
        def run(*args)
            temp_file = ".info_language_runner_cache.rb"
            IO.write(temp_file, @value)
            Process.wait(Process.spawn("ruby", temp_file, *args))
            File.delete(temp_file)
        end
    end
    register_tag('!language/ruby', RubyCode)
    # add an evaluater for ruby code
    ruby_evaluation_tag = 'evaluate/ruby'
    Code.tags[ruby_evaluation_tag] = "evaluate"
    YAML.add_domain_type("", ruby_evaluation_tag) do |type, value|
        if value.is_a? String
            eval(value)
        else
            value
        end
    end

    # 
    # Console Code
    # 
    # TODO: add support for console code
    class ConsoleCode < Code
        def run
            -"#{@value}"
        end
    end
    register_tag('!language/console', ConsoleCode)
# 
# project info (specific to operating sytem)
# 
# setting/getting values via an object (instead of opening/closing a file)
class Info
    
    # standard attributes
    @data = {}
    @paths = {}
    @commands = {}
    @path = nil
    
    # a helper error class
    class ReRaiseException < Exception
    end
    
    def initialize()
        # 
        # find the yaml file
        # 
        begin
            @path = Info.path
        rescue
            raise <<-HEREDOC.remove_indent
                
                
                When calling Info.new
                I looked for an info.yaml in #{Dir.pwd}
                (and I also looked in all of its parent folders)
                but I couldn't find an info.yaml file in any of them
            HEREDOC
        end
        # 
        # open the yaml file
        # 
        begin
            @data = YAML.load_file(@path)
        rescue => exception
            raise <<-HEREDOC.remove_indent
                
                When calling Info.new
                I found an info.yaml file
                however, when I tried to load it I received an error:
                #{exception}
            HEREDOC
        end
        # 
        # check the version, and parse accordingly
        # 
        version = nil
        begin
            version = Version.new(@data['(using_atk_version)'].to_s)
        rescue => exception
            # if no version, then don't worry about parsing
        end
        if nil != version
            begin
                if version <= Version.new("1.0.0")
                    self.parser_version1(@data)
                else
                    # TODO: in the future do an online check to see if the latest ATK could handle this
                    raise <<-HEREDOC.remove_indent
                        
                        Hey I think you need to update atk:
                            `atk update`
                        Why?
                            The (using_atk_version) in the info.yaml is: #{version}
                            However, I (your current version of ATK) don't know
                            how to handle that version.
                    HEREDOC
                end
            rescue ReRaiseException => exception
                raise exception
            rescue => exception
                raise <<-HEREDOC.remove_indent
                    
                    Original error message:
                    """
                    #{exception}
                    """
                    
                    This error is almost certainly not your fault
                    It is likely a bug inside the atk_toolbox library
                    Specifically the info.yaml parser
                    
                    If you agree and think this is a problem with the atk_toolbox library
                    please go here:
                    https://github.com/aggie-tool-kit/atk-toolbox/issues/new
                    and tell us what happened before getting this message
                    and also paste the original error message:
                    
                    Sorry for the bug!
                HEREDOC
            end
        end
    end

    def self.folder()
        folder = Dir.pwd
        loop do
            # if the info.yaml exists in that folder
            if FileSystem.file?( FileSystem.join(folder, "info.yaml"))
                return folder
            end

            next_location = File.dirname(folder)
            
            # if all folders exhausted
            if next_location == folder
                raise <<-HEREDOC.remove_indent.red
                    
                    #{"Couldn't find an info.yaml in the current directory or any parent directory".red}
                        #{Dir.pwd}
                    Are you sure you're running the command from the correct directory?
                HEREDOC
            end
            
            folder = next_location
        end
    end
    
    def self.path()
        return FileSystem.join( self.folder(), "info.yaml")
    end
    
    def parser_version1(data)
        # 
        # parse the commands
        #
        begin
            @commands = data['(project)']['(commands)']
            if !(@commands.is_a?(Hash))
                @commands = {}
            end
        rescue
            @commands = {}
        end
        # 
        # parse the paths
        # 
        begin
            @paths = data['(project)']['(paths)']
            if !(@paths.is_a?(Hash))
                @paths = {}
            end
        rescue
            @paths = {}
        end
        for each_key, each_value in @paths
            # if its an array, just join it together
            if each_value.is_a?(Array)
                each_value = FileSystem.join(*each_value)
            end
            # make all paths absolute
            if each_value.is_a?(String)
                # remove the ./ if it exists
                if each_value =~ /\A\.\//
                    each_value = each_value[2..-1]
                end
                # Dont add a source_path if its an absolute path
                if not each_value.size > 0 && each_value[0] == '/'
                    # convert the path into an absolute path
                    @paths[each_key] = FileSystem.join(absolute_parent_path , each_value)
                end
            end
        end
    end
    
    def self.init
        current_dir = Dir.pwd/"info.yaml"
        # if there isn't a info.yaml then create one
        if not File.file?(current_dir)
            # copy the default yaml to the current dir
            FileUtils.cp(__dir__/"default_info.yaml", current_dir)
            puts "info.yaml created successfully"
        else
            puts "There appears to already be an info.yaml file\nThe init method is not yet able to merge the ATK init data with the current data\n(this will be fixed in the future)"
        end
    end
    
    # read access
    def [](element)
        return @data[element]
    end
    
    def self.[](element)
        return (Info.new)[element]
    end
    
    # data access
    def data
        return @data
    end
    def self.data
        return (Info.new).data
    end
    
    # command access
    def commands
        return @commands || {}
    end
    def self.commands
        return (Info.new).commands
    end
    
    # path access
    def paths
        return @paths || {}
    end
    def self.paths
        return (Info.new).paths
    end
    
end