require_relative './extra_file_utils'
require_relative './os'
require 'yaml'

class AtkPaths
    def self.[](name)
        # convert symbols to strings
        name = name.to_s
        case name
            when 'atk'
                return HOME/"atk"
            when 'temp'
                return self['atk']/"temp"
            when 'info'
                return HOME/"info.yaml"
            when 'ruby'
                atk_path_settings = ATK.info["paths"]
                if atk_path_settings.is_a?(Hash) and atk_path_settings["ruby"].is_a?(String)
                    ruby_path = atk_path_settings["ruby"]
                elsif OS.is?(:unix)
                    ruby_path = "/usr/bin/ruby"
                else
                    # TODO: fix this case
                    ruby_path = ""
                end
                return ruby_path
        end
    end
end

module ATK
    def self.paths
        return AtkPaths
    end
    
    def self.temp_path(filepath)
        new_path = ATK.paths[:temp]/filepath
        # make sure the path is empty
        begin
            File.delete(new_path)
        end
        return new_path
    end
    
    def self.info
        settings_path = ATK.paths[:info]
        atk_settings_key = "atk_settings"
        # if it doesn't exist then create it
        if not File.exist?(settings_path)
            IO.write(settings_path, "#{atk_settings_key}: {}")
            return {}
        else
            data = YAML.load_file(settings_path)
            if data.is_a?(Hash)
                if data[atk_settings_key].is_a?(Hash)
                    puts "data[atk_settings_key] is: #{data[atk_settings_key]} "
                    return data[atk_settings_key]
                end
            else
                return {}
            end
        end
    end
end