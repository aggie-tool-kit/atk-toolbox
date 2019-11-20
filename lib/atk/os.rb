require_relative './version.rb'
# every OS version is a perfect heirarchy of versions and sub verisons that may or may not be chronological
# every OS gets it's own custom heirarchy since there are issues like x86 support and "student edition" etc
# the plan is to release this heirarchy on its own repo, and to get pull requests for anyone who wants to add their own OS
os_heirarchy = {
    "windows" => {
        "10"    => {},
        "8.1"   => {},
        "8"     => {},
        "7"     => {},
        "vista" => {},
        "xp"    => {},
        "95"    => {},
    },
    "mac" => {
        "mojave"         => {},
        "high sierra"    => {},
        "sierra"         => {},
        "el capitan"     => {},
        "yosemite"       => {},
        "mavericks"      => {},
        "mountain lion"  => {},
        "lion"           => {},
        "snow leopard"   => {},
        "leopard"        => {},
        "tiger"          => {},
        "panther"        => {},
        "jaguar"         => {},
        "puma"           => {},
        "cheetah"        => {},
        "kodiak"         => {},
    },
    "ubuntu"     => {},
    "arch"       => {},
    "manjaro"    => {},
    "deepin"     => {},
    "centos"     => {},
    "debian"     => {},
    "fedora"     => {},
    "elementary" => {},
    "zorin"      => {},
    "raspian"    => {},
    "android"    => {},
}

# TODO: look into using https://github.com/piotrmurach/tty-platform

# 
# Groups
# 
# the groups are the pratical side of the OS, they describe the OS rather than fit it prefectly into a heirarchy
module OS
    # TODO: have the version pick one of the verions in the os_heirarchy according to the current OS
    def self.version
        raise "not yet implemented"
    end
    
    def self.is?(adjective)
        # summary:
            # this is a function created for convenience, so it doesn't have to be perfect
            # you can use it to ask about random qualities of the current OS and get a boolean response
        # convert to string (if its a symbol)
        adjective = adjective.to_s.downcase
        case adjective
            when 'windows'
                return (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
            when 'mac'
                return (/darwin/ =~ RUBY_PLATFORM) != nil
            when 'linux'
                return (not OS.is?(:windows)) && (not OS.is?(:mac))
            when 'unix'
                return not( OS.is?(:windows))
            when 'debian'
                return File.file?('/etc/debian_version')
            when 'ubuntu'
                return OS.has_command('lsb_release') && `lsb_release -a`.match(/Distributor ID: Ubuntu/)
        end
    end
    
    def self.version
        # these statements need to be done in order from least to greatest
        if OS.is?("ubuntu")
            if OS.has_command('lsb_release')
                version_info = `lsb_release -a`
                version = Version.extract_from(version_info)
                name_area = version_info.match(/Codename: *(.+)/)
                if name_area
                    version.codename = name_area[1].strip
                end
                return version
            end
        elsif OS.is?("debian")
            # TODO: support debian version
            return nil
        elsif OS.is?('mac')
            version = Version.extract_from(`system_profiler SPSoftwareDataType`)
            agreement_file = `cat '/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf'`
            codename_match = agreement_file.match(/SOFTWARE LICENSE AGREEMENT FOR *(?:macOS)? *(.+)\\\n/)
            if codename_match
                version.codename = codename_match[1].strip
            end
            return version
        elsif OS.is?('windows')
            # TODO: support windows version
            return nil
        end
    end
    
    def self.path_for_executable(name_of_executable)
        if OS.is?(:windows)
            return `where '#{name_of_executable}'`.strip
        else
            return `which '#{name_of_executable}'`.strip
        end
    end
    
    def self.has_command(name_of_executable)
        return OS.path_for_executable(name_of_executable) != ''
    end
end