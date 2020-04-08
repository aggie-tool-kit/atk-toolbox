module Atk
    def self.autocomplete(which_command)
        # FUTURE: correct the bugs
        # if which_command == '_'
        #     require_relative './info.rb'
        #     begin
        #         puts Info.commands().keys.map { |each| each.gsub(' ', '\ ') }.join(' ')
        #     rescue => exception
        #         puts ""
        #     end
        # end
    end
    
    # 
    # zsh autocomplete
    # 
        #     _atk()
        # {
        #     local comp_words="${COMP_WORDS[1]}"
        #     local comp_cword="${COMP_CWORD}"
        #     local mylist="$( ruby -e  '
        #                         require "yaml"
        #                         class Nil ; def [](); end; end;
        #                         if ARGV[1] == "1"
        #                             puts YAML.load_file("./info.yaml")["(project)"]["(commands)"].keys.select { |each| each if each.start_with?(ARGV[0]) }
        #                         else
        #                             puts `ls`
        #                         end
        #                     ' $comp_words $comp_cword
        #     )"
        #     COMPREPLY=($(compgen -W $mylist) )
        #     # compadd $mylist
        #     _alternative "arguments:custom arg:((test_gym test_thing))"
        # }

        # # autoload -U predict-on
        # # zle -C _expand_word .complete-word _atk

        # complete -F _atk _
        # compdef _atk _
end