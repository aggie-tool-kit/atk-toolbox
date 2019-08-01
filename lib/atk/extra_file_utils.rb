require 'etc'
require 'fileutils'
require 'set'

HOME = Etc.getpwuid.dir

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