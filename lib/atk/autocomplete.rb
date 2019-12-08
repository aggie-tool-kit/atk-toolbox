module Atk
    def self.autocomplete(which_command)
        if which_command == '_'
            require_relative './yaml_info_parser.rb'
            begin
                puts Info.project_commands().keys.map { |each| each.gsub(' ', '\ ') }.join(' ')
            rescue => exception
                puts ""
            end
        end
    end
end