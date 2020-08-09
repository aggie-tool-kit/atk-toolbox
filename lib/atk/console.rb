require_relative "./os.rb"
require_relative "../console_colors.rb"
require_relative "./remove_indent.rb"

# easy access to the commandline
module Atk
    refine String do
        # add a - operator to strings that makes it behave like a system() call 
        def -@
            return system(self)
        end
    end
end

class CommandResult
    def initialize(io_object, process_object)
        @io_object = io_object
        @process_object = process_object
    end
    
    def read
        if @read == nil && @io_object
            @read = @io_object.read
        end
        return @read
    end
    
    def exitcode
        if !@io_object
            return Errno::ENOENT.new
        end
    end
    
    class Error < Exception
        attr_accessor :command_result, :message
        
        def initialize(message, command_result)
            @message = message
            @command_result = command_result
        end
        
        def to_s
            return @message
        end
    end
end



# 
# Console 
# 
Console = Class.new do
    
    CACHE = Class.new do
        attr_accessor :prompt
    end.new
    
    # 
    # prompt properties
    # 
    # see https://github.com/piotrmurach/tty-prompt
    def _load_prompt
        require "tty-prompt"
        CACHE::prompt = TTY::Prompt.new
    end
    # generate interface for TTY prompt with lazy require
    for each in [ :ask, :keypress, :multiline, :mask, :yes?, :no?, :select, :multi_select, :enum_select, :expand, :collect, :suggest, :slider, :say, :warn, :error ]
        eval(<<-HEREDOC)
            def #{each}(*args, **kwargs)
                self._load_prompt() if CACHE::prompt == nil
                if block_given?
                    CACHE::prompt.#{each}(*args, **kwargs) do |*block_args, **block_kwargs|
                        yield(*block_args, **block_kwargs)
                    end
                else
                    CACHE::prompt.#{each}(*args, **kwargs)
                end
            end
        HEREDOC
    end
    
    def ok(message)
        puts message.green + "\n[press enter to continue]".light_black
        gets
    end
    alias :ok? :ok
    
    attr_accessor :verbose
    
    def _save_args
        if @args == nil
            @args = []
            for each in ARGV
                @args << each
            end
        end
    end
    
    def args
        self._save_args()
        return @args
    end
    
    def stdin
        # save arguments before clearing them
        self._save_args()
        # must clear arguments in order to get stdin
        ARGV.clear
        # check if there is a stdin
        if !(STDIN.tty?)
            @stdin = $stdin.read
        end
        return @stdin
    end
    
    #
    # returns the command object, ignores errors
    #
    def run!(command, **keyword_arguments)
        if command.is_a?(String)
            # by default return a string with stderr included
            begin
                command_info = IO.popen(command, err: [:child, :out])
                Process.wait(command_info.pid)
                process_info = $?
                result = CommandResult.new(command_info, process_info)
                if keyword_arguments[:silent] != true
                    puts result.read
                end
            rescue
                process_info = $?
                result = CommandResult.new(nil, process_info)
            end
            return result
        else
            raise <<-HEREDOC.remove_indent
                
                
                The argument for run!() must be a string
                this restriction will be lifted in the future
            HEREDOC
        end
    end

    # 
    # returns true if successful, false/nil on error
    # 
    def run?(command, **keyword_arguments)
        if command.is_a?(String)
            return system(command)
        else
            raise <<-HEREDOC.remove_indent
                
                
                The argument for run?() must be a string
                this restriction will be lifted in the future
            HEREDOC
        end
    end

    # 
    # returns process info if successful, raises error if command failed
    # 
    def run(command, **keyword_arguments)
        if command.is_a?(String)
            # by default return a string with stderr included
            begin
                command_info = IO.popen(command, err: [:child, :out])
                Process.wait(command_info.pid)
                process_info = $?
                result = CommandResult.new(command_info, process_info)
                if keyword_arguments[:silent] != true
                    puts result.read
                end
            rescue
                process_info = $?
                result = CommandResult.new(nil, process_info)
            end
            # if ended with error
            if !process_info.success?
                # then raise an error
                raise CommandResult::Error.new(<<-HEREDOC.remove_indent, result)
                    
                    
                    From run(command)
                    The command: #{command.color_as :code}
                    Failed with a exitcode of: #{process_info.exitstatus}
                    
                    #{"This likely means the command could not be found" if process_info.exitstatus == 127}
                    #{"Hopefully there is additional error info above" if process_info.exitstatus != 127}
                HEREDOC
            end
            return result
        else
            raise <<-HEREDOC.remove_indent
                
                
                The argument for run() must be a string
                this restriction will be lifted in the future
            HEREDOC
        end
    end
    
    def path_for(name_of_executable)
        return OS.path_for_executable(name_of_executable)
    end
    
    def has_command(name_of_executable)
        return OS.has_command(name_of_executable)
    end
    alias :has_command? :has_command
    
    def as_shell_argument(argument)
        argument = argument.to_s
        if OS.is?(:unix)
            # use single quotes to perfectly escape any string
            return " '"+argument.gsub(/'/, "'\"'\"'")+"'"
        else
            # *sigh* Windows
            # this problem is unsovleable
            # see: https://superuser.com/questions/182454/using-backslash-to-escape-characters-in-cmd-exe-runas-command-as-example
            #       "The fact is, there's nothing that will escape " within quotes for argument passing. 
            #        You can brood over this for a couple of years and arrive at no solution. 
            #        This is just some of the inherent limitations of cmd scripting.
            #        However, the good news is that you'll most likely never come across a situation whereby you need to do so.
            #        Sure, there's no way to get echo """ & echo 1 to work, but that's not such a big deal because it's simply
            #        a contrived problem which you'll likely never encounter.
            #        For example, consider runas. It works fine without needing to escape " within quotes
            #        because runas knew that there's no way to do so and made internal adjustments to work around it.
            #        runas invented its own parsing rules (runas /flag "anything even including quotes") and does not
            #        interpret cmd arguments the usual way.
            #        Official documentation for these special syntax is pretty sparse (or non-existent).
            #        Aside from /? and help, it's mostly trial-and-error."
            # 
            
            
            # according to Microsoft see: https://docs.microsoft.com/en-us/archive/blogs/twistylittlepassagesallalike/everyone-quotes-command-line-arguments-the-wrong-way
            # the best possible (but still broken) implementation is to quote things 
            # in accordance with their default C++ argument parser
            # so thats what this function does
            
            # users are going to have to manually escape things like ^, !, % etc depending on the context they're used in
            
            simple_char = "[a-zA-Z0-9_.,;`=\\-*?\\/\\[\\]]"
            
            # if its a simple argument just pass it on
            if argument =~ /\A(#{simple_char})*\z/
                return " #{argument}"
            # if it is complicated, then quote it and escape quotes
            else
                # find any backslashes that come before a double quote or the ending of the argument
                # then double the number of slashes
                escaped = argument.gsub(/(\/+)(?="|\z)/) do |each_match|
                    "\/" * ($1.size * 2)
                end
                
                # then find all the double quotes and escape them
                escaped.gsub!(/"/, '\\"')
                
                # all of the remaining escapes are up to Windows user's/devs

                return " \"#{escaped}\""
            end
        end
    end
    
    def make_arguments_appendable(arguments)
        safe_arguments = arguments.map do |each|
            Console.as_shell_argument(each)
        end
        return safe_arguments.join('')
    end
    
    # returns the locations where commands are stored from highest to lowest priority
    def command_sources()
        if OS.is?('unix')
            return ENV['PATH'].split(':')
        else
            return ENV['PATH'].split(';')
        end
    end
    
    def require_superuser()
        if OS.is?('unix')
            system("sudo echo 'permissions acquired'")
        else
            # check if already admin
            # $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            # $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            # FUTURE: add a check here and raise an error if not admin
            puts "(in the future this will be an automatic check)"
            puts "(if you're unsure, then the answer is probably no)"
            if Console.yes?("Are you running this \"as an Administrator\"?\n(caution: incorrectly saying 'yes' can cause broken systems)")
                puts "assuming permissions are acquired"
            else
                puts <<-HEREDOC.remove_indent
                    
                    You'll need to 
                    - close the current program
                    - reopen it "as Administrator"
                    - redo whatever steps you did to get here
                    
                HEREDOC
                Console.keypress("Press enter to end the current process", keys: [:return])
                exit
            end
        end
    end
    
    def set_command(name, code)
        require_relative './file_system'
        require_relative './os'
        require_relative './atk_info'
        if OS.is?("unix")
            exec_path = "#{Atk.paths[:commands]}/#{name}"
            local_place = Atk.temp_path(name)
            # add the hash bang
            hash_bang = "#!#{Atk.paths[:ruby]}\n"
            # create the file
            FS.write(hash_bang+code, to: local_place)
            # copy to command folder
            system("sudo", "cp", local_place, exec_path)
            system("sudo", "chmod", "ugo+x", exec_path)
        elsif OS.is?("windows")
            # check for invalid file paths, see https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file
            if name =~ /[><:"\/\\|?*]/
                raise <<-HEREDOC.remove_indent
                    
                    
                    When using the ATK Console.set_command(name)
                    The name: #{name}
                    is not a valid file path on windows
                    which means it cannot be a command
                HEREDOC
            end
            exec_path = "#{Atk.paths[:commands]}\\#{name}"
            
            # create the code
            IO.write(exec_path+".rb", code)
            # create an executable to call the code
            IO.write(exec_path+".bat", "@echo off\nruby \"#{exec_path}.rb\" %*")
        end
    end
end.new

def log(*args)
    if Console.verbose
        puts(*args)
    end
end