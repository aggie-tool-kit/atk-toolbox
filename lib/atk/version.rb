# create a variable for the current ruby version

class Version
    attr_accessor :major, :minor, :patch
    
    def initialize(version_as_string)
        # TODO: make this more safe/better error handling
        @major, @minor, @patch = version_as_string.split('.').map{|each| each.to_i}
        @as_string = version_as_string
    end
    
    def <=>(other_version)
        if not other_version.is_a?(Version)
            raise "When doing version comparision, both sides must be a version object"
        end
        major_size = (@major <=> other_version.major * 100)
        minor_size = (@minor <=> other_version.minor * 10 )
        patch_size = (@patch <=> other_version.patch * 1 )
        return (major_size + minor_size + patch_size) <=> 0
    end
    
    def >(other_version)
        return (self <=> other_version) == 1
    end
    
    def <(other_version)
        return (self <=> other_version) == -1
    end
    
    def ==(other_version)
        return (self <=> other_version) == 0
    end
    
    def to_s
        return "#{@major}.#{@minor}.#{@patch}"
    end
end

VERSION_OF_RUBY = Version.new(RUBY_VERSION)