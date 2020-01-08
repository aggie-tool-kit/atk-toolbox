require "tty-prompt"
require_relative "./os.rb"
require_relative "../console_colors.rb"


# TODO: switch to using https://github.com/piotrmurach/tty-command#2-interface 

# easy access to the commandline
class String
    # add a - operator to strings that makes it behave like a system() call 
    # but it returns a success value for chaining commands with || or &&
    def -@
        Process.wait(Process.spawn(self))
        return $?.success?
    end
end


# 
# Console 
# 
# see https://github.com/piotrmurach/tty-prompt
# TODO: look into https://piotrmurach.github.io/tty/  to animate the terminal
# TODO: look at https://github.com/pazdera/catpix to add an ATK logo in the terminal
class TTY::Prompt
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
    
    def path_for(name_of_executable)
        return OS.path_for_executable(name_of_executable)
    end
    
    def has_command(name_of_executable)
        return OS.has_command(name_of_executable)
    end
    alias :has_command? :has_command
    
    def single_quote_escape(string)
        string.gsub(/'/, "'\"'\"'")
    end
    
    def make_arguments_appendable(arguments)
        # TODO: make sure this works on windows
        safe_arguments = arguments.map do |each|
            " '"+Console.single_quote_escape(each)+"'"
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
            # TODO: add a check here and raise an error if not admin
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
    
    # note: this likely requires a terminal restart
    # def command_sources=(new_locations)
    #     # TODO: add saftey checks on new_locations, check for empty list and that all of them are strings
    #     Console.require_superuser()
    #     if OS.is?('unix')
    #         new_locations = new_locations.join(':')
    #         if OS.is?('mac')
                
    #             # IO.write('/etc/paths')
    #         end
    #     else
    #         new_locations = new_locations.join(';')
    #         system("setx", "path", new_locations)
    #         puts "Your command line will need to retart for path changes to take effect"
    #     end
    # end
    
end

Console = TTY::Prompt.new

def log(*args)
    if Console.verbose
        puts(*args)
    end
end