# create a variable for the current ruby version

class Version
    attr_accessor :levels, :codename
    
    def self.extract_from(string)
        match = string.match(/\d+\.\d+(\.\d+)*/)
        if match != nil
            return Version.new(match[0])
        end
    end
    
    def initialize(version_as_string)
        # if there are no digits
        if !(version_as_string.to_s =~ /\d/)
            raise <<-HEREDOC.remove_indent
                
                
                When calling Version.new(arg1)
                the `arg1.to_s` was #{version_as_string.to_s}
                which does not contain any digits
                so the Version class doesn't know what to do with it
            HEREDOC
        end
        @levels = version_as_string.split('.')
        @comparable = @levels[0] =~ /\A\d+\z/
        # convert values into integers where possible
        index = -1
        for each in @levels.dup
            index += 1
            if each =~ /\A\d+\z/
                @levels[index] = each.to_i
            end
        end
        @major, @minor, @patch, *_ = @levels
    end
    
    def patch() @patch end
    def patch=(new_value)
        @levels[2] = new_value
    end
    def minor() @minor end
    def minor=(new_value)
        @levels[1] = new_value
    end
    def major() @major end
    def major=(new_value)
        @levels[0] = new_value
    end
    
    def comparable?
        return @comparable
    end
    
    def <=>(other_version)
        if not other_version.is_a?(Version)
            raise "When doing version comparision, both sides must be a version object"
        end
        if other_version.to_s == self.to_s
            return 0
        end
        
        if other_version.comparable? && self.comparable?
            self_levels = @levels.dup
            other_levels = other_version.levels.dup
            loop do
                if self_levels.size == 0 || other_levels.size == 0
                    if self_levels.size > other_levels.size
                        return 1
                    elsif self_levels.size < other_levels.size
                        return -1
                    else
                        return 0
                    end
                end
                comparision = self_levels.shift() <=> other_levels.shift()
                if comparision != 0
                    return comparision
                end
            end
        else
            return nil
        end
    end
    
    def >(other_version)
        value = (self <=> other_version)
        return value && value == 1
    end
    
    def <(other_version)
        value = (self <=> other_version)
        return value && value == -1
    end
    
    def ==(other_version)
        value = (self <=> other_version)
        return value && value == 0
    end
    
    def to_s
        return @levels.map(&:to_s).join('.')
    end
end

VERSION_OF_RUBY = Version.new(RUBY_VERSION)