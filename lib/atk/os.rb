require_relative './version.rb'

# this statment was extracted from the ptools gem, credit should go to them
# https://github.com/djberg96/ptools/blob/master/lib/ptools.rb
# The WIN32EXTS string is used as part of a Dir[] call in certain methods.
if File::ALT_SEPARATOR
    MSWINDOWS = true
    if ENV['PATHEXT']
        WIN32EXTS = ('.{' + ENV['PATHEXT'].tr(';', ',').tr('.','') + '}').downcase
    else
        WIN32EXTS = '.{exe,com,bat}'
    end
else
    MSWINDOWS = false
end

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
    
    # create a singleton class
    class << (OS::CACHE = Object.new)
        attr_accessor :is_windows, :is_mac, :is_linux, :is_unix, :is_debian, :is_ubuntu
    end
    
    def self.is?(adjective)
        # summary:
            # this is a function created for convenience, so it doesn't have to be perfect
            # you can use it to ask about random qualities of the current OS and get a boolean response
        # convert to string (if its a symbol)
        adjective = adjective.to_s.downcase
        case adjective
            when 'windows'
                if OS::CACHE::is_windows == nil
                    OS::CACHE::is_windows = (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
                end
                return OS::CACHE::is_windows
            when 'mac'
                if OS::CACHE::is_mac == nil
                    OS::CACHE::is_mac = (/darwin/ =~ RUBY_PLATFORM) != nil
                end
                return OS::CACHE::is_mac
            when 'linux'
                if OS::CACHE::is_linux == nil
                    OS::CACHE::is_linux = (not OS.is?(:windows)) && (not OS.is?(:mac))
                end
                return OS::CACHE::is_linux
            when 'unix'
                if OS::CACHE::is_unix == nil
                    OS::CACHE::is_unix = not(OS.is?(:windows))
                end
                return OS::CACHE::is_unix
            when 'debian'
                if OS::CACHE::is_debian == nil
                    OS::CACHE::is_debian = File.file?('/etc/debian_version')
                end
                return OS::CACHE::is_debian
            when 'ubuntu'
                if OS::CACHE::is_ubuntu == nil
                    OS::CACHE::is_ubuntu = OS.has_command('lsb_release') && `lsb_release -a`.match(/Distributor ID:[\s\t]*Ubuntu/)
                end
                return OS::CACHE::is_ubuntu
        end
    end
    
    def self.version
        # these statements need to be done in order from least to greatest
        if OS.is?("ubuntu")
            version_info = `lsb_release -a`
            version = Version.extract_from(version_info)
            name_area = version_info.match(/Codename: *(.+)/)
            if name_area
                version.codename = name_area[1].strip
            end
            return version
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
        program = name_of_executable
        # this method was extracted from the ptools gem, credit should go to them
        # https://github.com/djberg96/ptools/blob/master/lib/ptools.rb
        # this complex method is in favor of just calling the command line because command line calls are slow
        path=ENV['PATH']
        if path.nil? || path.empty?
            raise ArgumentError, "path cannot be empty"
        end

        # Bail out early if an absolute path is provided.
        if program =~ /^\/|^[a-z]:[\\\/]/i
            program += WIN32EXTS if MSWINDOWS && File.extname(program).empty?
            found = Dir[program].first
            if found && File.executable?(found) && !File.directory?(found)
                return found
            else
                return nil
            end
        end

        # Iterate over each path glob the dir + program.
        path.split(File::PATH_SEPARATOR).each{ |dir|
            dir = File.expand_path(dir)

            next unless File.exist?(dir) # In case of bogus second argument
            file = File.join(dir, program)

            # Dir[] doesn't handle backslashes properly, so convert them. Also, if
            # the program name doesn't have an extension, try them all.
            if MSWINDOWS
                file = file.tr("\\", "/")
                file += WIN32EXTS if File.extname(program).empty?
            end

            found = Dir[file].first

            # Convert all forward slashes to backslashes if supported
            if found && File.executable?(found) && !File.directory?(found)
                found.tr!(File::SEPARATOR, File::ALT_SEPARATOR) if File::ALT_SEPARATOR
                return found
            end
        }

        return nil
    end
    
    def self.has_command(name_of_executable)
        return OS.path_for_executable(name_of_executable) != nil
    end
end