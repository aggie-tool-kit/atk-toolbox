require 'etc'
require 'fileutils'
require 'set'
require_relative './os'

if OS.is?("unix")
    HOME = Etc.getpwuid.dir
else # windows
    HOME = `echo %HOMEPATH%`.chomp
end

class String
    def /(next_string)
        if OS.is?("windows")
            self + "\\" + next_string
        else
            File.join(self, next_string)
        end
    end
end

class FileSys
    def self.in_dir(path_to_somewhere)
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
    
    def self.write(data, to:nil)
        # make sure the containing folder exists
        FileUtils.makedirs(File.dirname(to))
        # actually download the file
        IO.write(to, data)
    end
    
    def self.read(filepath)
        begin
            return IO.read(filepath)
        rescue => exception
            return nil
        end
    end
    
    def self.delete(filepath)
        begin
            return File.delete(filepath)
        # if file doesnt exist, thats fine
        rescue Errno::ENOENT => exception
            return nil
        end
    end
end