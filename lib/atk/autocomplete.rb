module Atk
    def self.autocomplete(which_command)
        if which_command == '_'
            require_relative './info.rb'
            begin
                puts Info.commands().keys.map { |each| each.gsub(' ', '\ ') }.join(' ')
            rescue => exception
                puts ""
            end
        end
    end
end