require "tty-prompt"
require_relative "./os.rb"
require_relative "../console_colors.rb"

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
            
            simple_char = /[a-zA-Z0-9_.,;`=-*?\/\[\]]/
            
            # if its a simple argument just pass it on
            if argument =~ /\A(#{simple_char})*\z/
                return " #{argument}"
            # if it is complicated, then quote it and escape quotes
            else
                # find any backslashes that come before a double quote or the ending of the argument
                # then double the number of slashes
                escaped = argument.gsub(/(?<slashes>\/+)(?="|\z)/) do |each_match|
                    "\/" * (each_match['slashes'].size * 2)
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