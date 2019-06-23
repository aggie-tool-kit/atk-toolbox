# 
# extract all the command line input so STDIN can be used 
#
def commandline_args() 
    the_args = []
    for each in ARGV
        the_args << each
    end
    ARGV.clear
    return the_args
end

# TODO: switch to using https://github.com/piotrmurach/tty-command#2-interface 

# easy access to the commandline
class String
    # add a - operator to strings that makes it behave like a system() call 
    # but it shows stderr 
    def -@
        Process.wait(Process.spawn(self))
        return $?.success?
    end
end


# 
# Q&A Functions
# 
# TODO: replace these with https://github.com/piotrmurach/tty-prompt
def ask_yes_or_no(question)
    loop do 
        puts question
        case gets.chomp
        when /\A\s*(yes|yeah|y)\z\s*/i
            return true
        when /\A\s*(no|nope|n)\z\s*/i
            return false
        when /\A\s*cancel\s*\z/i
            raise 'user canceled yes or no question'
        else
            puts "Sorry, please answer 'yes', 'no', or 'cancel'"
        end#case
    end#loop 
end#askYesOrNo

