require "tty-prompt"

# TODO: switch to using https://github.com/piotrmurach/tty-command#2-interface 

# easy access to the commandline
class String
    # add a - operator to strings that makes it behave like a system() call 
    # but it shows stderr and returns a success value
    def -@
        Process.wait(Process.spawn(self))
        return $?.success?
    end
end


# 
# Q&A Functions
# 
# TODO: replace these with https://github.com/piotrmurach/tty-prompt
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
end

Console = TTY::Prompt.new

def log(*args)
    if Console.verbose
        puts(*args)
    end
end
