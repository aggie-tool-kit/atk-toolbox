require 'etc'
require 'fileutils'
require 'set'
require_relative './os'

if OS.is?("unix")
    HOME = Etc.getpwuid.dir
else # windows
    HOME = `echo C:%HOMEPATH%`
end

class String
    def /(next_string)
        File.join(self, next_string)
    end
end


def in_dir(path_to_somewhere)
    # save the current working dir
    current_dir = Dir.pwd
    # switch dirs
    Dir.chdir(path_to_somewhere)
    # do the thing
    output = yield
    # switch back
    Dir.chdir(current_dir)
    return output
end