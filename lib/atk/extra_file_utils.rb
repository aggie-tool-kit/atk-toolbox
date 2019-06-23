require 'etc'
HOME = Etc.getpwuid.dir

class String
    def /(next_string)
        File.join(self, next_string)
    end
end