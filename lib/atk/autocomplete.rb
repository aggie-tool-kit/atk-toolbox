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
        #compdef _

        # _atk()
        # {
        #     orig_words=( ${words[@]} )
        #     local comp_words="${COMP_WORDS[1]}"
        #     local comp_cword="${COMP_CWORD}"
        #     local mylist="$( ruby -e  '
        #                         require "yaml"
        #                         class Nil ; def [](); end; end;
        #                         if ARGV.length == 2
        #                             puts YAML.load_file("./info.yaml")["(project)"]["(commands)"].keys.map{|each| each.inspect}
        #                         else
        #                             # puts `ls`
        #                         end
        #                     ' $orig_words
        #     )"
        #     COMPREPLY=($(compgen -W $mylist) )
        #     _alternative "arguments:custom arg:(($mylist))"
        # }

        # complete -F _atk _
        # compdef _atk _
end