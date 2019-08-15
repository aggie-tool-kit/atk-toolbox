require_relative './file_sys'
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
            when 'core_yaml'
                return HOME/"atk"/"core.yaml"
            when 'installed_yaml'
                return HOME/"atk"/"installers.yaml"
            when 'installers_folder'
                return HOME/"atk"/"installers"
        end
    end
end

module ATK
    def self.paths
        return AtkPaths
    end
    
    def self.temp_path(filename)
        new_path = ATK.paths[:temp]/filename
        # make sure the path is empty
        FS.write("", to: new_path)
        FS.delete(new_path)
        return new_path
    end
    
    def self.info
        settings_path = ATK.paths[:info]
        atk_settings_key = "atk_settings"
        # if it doesn't exist then create it
        if not FS.exist?(settings_path)
            FS.write("#{atk_settings_key}: {}", to: settings_path)
            return {}
        else
            data = YAML.load_file(settings_path)
            if data.is_a?(Hash)
                if data[atk_settings_key].is_a?(Hash)
                    return data[atk_settings_key]
                end
            else
                return {}
            end
        end
    end
end