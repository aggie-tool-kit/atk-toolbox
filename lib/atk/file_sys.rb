require 'etc'
require 'fileutils'
require 'pathname'
require 'open-uri'
require 'json'
require 'yaml'
require 'csv'
require_relative './os'
require_relative './remove_indent'

if OS.is?("unix")
    HOME = Etc.getpwuid.dir
else # windows
    HOME = `echo %HOMEPATH%`.chomp
end

class String
    # this is for easy creation of cross-platform filepaths
    # ex: "foldername"/"filename"
    def /(next_string)
        if OS.is?("windows")
            self + "\\" + next_string
        else
            File.join(self, next_string)
        end
    end
end

class FileSys
    # This is a combination of the FileUtils, File, Pathname, IO, Etc, and Dir classes,
    # along with some other helpful methods
    # It is by-default forceful (dangerous/overwriting)
    # it is made to get things done in a no-nonsense error-free way and to have every pratical tool in one place

    # TODO
        # change_owner
        # set_permissions
        # relative_path_between
        # relative_path_to
        # add a force: true option to most of the commands
    
    def self.write(data, to:nil)
        # make sure the containing folder exists
        FileSys.makedirs(File.dirname(to))
        # actually download the file
        IO.write(to, data)
    end
    
    def self.save(value, to:nil, as:nil)
        # assume string if as was not given
        if as == nil
            as = :s
        end
        
        # add a special exception for csv files
        case as
        when :csv
            FS.write(value.map(&:to_csv).join, to: to)
        else
            conversion_method_name = "to_#{as}"
            if value.respond_to? conversion_method_name
                # this is like calling `value.to_json`, `value.to_yaml`, or `value.to_csv` but programatically
                string_value = value.public_send(conversion_method_name)
                if not string_value.is_a?(String)
                    raise <<-HEREDOC.remove_indent
                    
                    
                        The FileSys.save(value, to: #{to.inspect}, as: #{as.inspect}) had a problem.
                        The as: #{as}, gets converted into value.to_#{as}
                        Normally that returns a string that can be saved to a file
                        However, the value.to_#{as} did not return a string.
                        Value is of the #{value.class} class. Add a `to_#{as}` 
                        method to that class that returns a string to get FileSys.save() working
                    HEREDOC
                end
                FS.write(string_value, to:to)
            else
                raise <<-HEREDOC.remove_indent
                
                
                    The FileSys.save(value, to: #{to.inspect}, as: #{as.inspect}) had a problem.
                    
                    The as: #{as}, gets converted into value.to_#{as}
                    Normally that returns a string that can be saved to a file
                    However, the value.to_#{as} is not a method for value
                    Value is of the #{value.class} class. Add a `to_#{as}` 
                    method to that class that returns a string to get FileSys.save() working
                HEREDOC
            end
        end
    end
    
    def self.read(filepath)
        begin
            return IO.read(filepath)
        rescue Errno::ENOENT => exception
            return nil
        end
    end
    
    def self.delete(path)
        if File.file?(path)
            File.delete(path)
        elsif File.directory?(path)
            FileUtils.rm_rf(path)
        end
    end
    
    def self.username
        if OS.is?(:windows)
            return File.basename(ENV["userprofile"])
        else
            return Etc.getlogin
        end
    end
    
    def self.makedirs(path)
        FileUtils.makedirs(path)
    end
    
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
    
    def self.copy(from:nil, to:nil, new_name:"", force: true, preserve: false, dereference_root: false)
        if new_name == ""
            raise "\n\nFileSys.copy() needs a new_name: argument\nset new_name:nil if you wish the file/folder to keep the same name\ne.g. FileSys.copy(from:'place/thing', to:'place', new_name:nil)"
        elsif new_name == nil
            new_name = File.basename(from)
        end
        # make sure the "to" path exists
        FileSys.touch_dir(to)
        # perform the copy
        FileUtils.copy_entry(from, to/new_name, preserve, dereference_root, force)
    end

    def self.move(from:nil, to:nil, new_name:"", force: true, noop: nil, verbose: nil, secure: nil)
        if new_name == ""
            raise "\n\nFileSys.move() needs a new_name: argument\nset new_name:nil if you wish the file/folder to keep the same name\ne.g. FileSys.move(from:'place/thing', to:'place', new_name:nil)"
        elsif new_name == nil
            new_name = File.basename(from)
        end
        # make sure the "to" path exists
        FileSys.touch_dir(to)
        # perform the move
        FileUtils.move(from, to/new_name, force: force, noop: noop, verbose: verbose, secure: secure)
    end
    
    def self.rename(from:nil, to:nil, force: true)
        # if the directories are different, then throw an error
        if not File.identical?(File.dirname(from), File.dirname(to))
            raise "\n\nFileSys.rename() requires that the the file stay in the same place and only change names.\nIf you want to move a file, use FileSys.move()"
        end
        # make sure the path is clear
        if force
            FileSys.delete(to)
        end
        # perform the copy
        File.rename(from, to)
    end
    
    def self.touch(*args)
        return FileUtils.touch(*args)
    end
    
    def self.touch_dir(path)
        if not FileSys.directory?(path)
            FileUtils.makedirs(path)
        end
    end
    
    # Pathname aliases
    def self.absolute_path?(path)
        Pathname.new(path).absolute?
    end
    def self.abs?(path)
        Pathname.new(path).absolute?
    end
    def self.relative_path?(path)
        Pathname.new(path).relative?
    end
    def self.rel?(path)
        Pathname.new(path).relative?
    end
    
    # dir aliases
    def self.home
        HOME
    end
    def self.glob(path)
        Dir.glob(path, File::FNM_DOTMATCH) - %w[. ..]
    end
    def self.list_files(path=".")
        Dir.children(path).map{|each| FS.dirname(path)/each }.select {|each| FileSys.file?(each)}
    end
    def self.list_folders(path=".")
        Dir.children(path).map{|each| FS.dirname(path)/each }.select {|each| FileSys.directory?(each)}
    end
    def self.ls(path=".")
        Dir.children(path)
    end
    def self.pwd
        Dir.pwd
    end
    def self.cd(*args, verbose: false)
        if args.size == 0
            args[0] = FS.home
        end
        FileUtils.cd(args[0], verbose: verbose)
    end
    def self.chdir(*args)
        FS.cd(*args)
    end
    
    # File aliases
    def self.time_access(*args)
        File.atime(*args)
    end
    def self.time_created(*args)
        File.birthtime(*args)
    end
    def self.time_modified(*args)
    end
    def self.folder?(*args)
        File.directory?(*args)
    end
    def self.dir?(*args)
        File.directory?(*args)
    end
    def self.exists?(*args)
        File.exist?(*args)
    end
    
    # inherit from File
    def self.absolute_path(*args)
        File.absolute_path(*args)
    end
    def self.dirname(*args)
        File.dirname(*args)
    end
    def self.basename(*args)
        File.basename(*args)
    end
    def self.extname(*args)
        File.extname(*args)
    end
    def self.directory?(*args)
        File.directory?(*args)
    end
    def self.file?(*args)
        File.file?(*args)
    end
    def self.empty?(*args)
        File.empty?(*args)
    end
    def self.exist?(*args)
        File.exist?(*args)
    end
    def self.executable?(*args)
        File.executable?(*args)
    end
    def self.symlink?(*args)
        File.symlink?(*args)
    end
    def self.owned?(*args)
        File.owned?(*args)
    end
    def self.pipe?(*args)
        File.pipe?(*args)
    end
    def self.readable?(*args)
        File.readable?(*args)
    end
    def self.size?(*args)
        if File.directory?(args[0])
            # recursively get the size of the folder
            return Dir.glob(File.join(args[0], '**', '*')).map{ |f| File.size(f) }.inject(:+)
        else
            File.size?(*args)
        end
    end
    def self.socket?(*args)
        File.socket?(*args)
    end
    def self.world_readable?(*args)
        File.world_readable?(*args)
    end
    def self.world_writable?(*args)
        File.world_writable?(*args)
    end
    def self.writable?(*args)
        File.writable?(*args)
    end
    def self.writable_real?(*args)
        File.writable_real?(*args)
    end
    def self.expand_path(*args)
        File.expand_path(*args)
    end
    def self.mkfifo(*args)
        File.mkfifo(*args)
    end
    def self.stat(*args)
        File.stat(*args)
    end
    
    def self.download(input=nil, from:nil, url:nil, to:nil)
        # if only one argument, either input or url
        if ((input!=nil) != (url!=nil)) && (from==nil) && (to==nil)
            # this covers:
            #    download     'site.com/file'
            the_url = url || input
            file_name = the_url.match /(?<=\/)[^\/]+\z/ 
            file_name = file_name[0]
        elsif (to != nil) && ((input!=nil)!=(url!=nil))
            # this covers:
            #    download     'site.com/file' to:'file'
            #    download url:'site.com/file' to:'file'
            the_url = url || input
            file_name = to
        elsif ((from!=nil) != (url!=nil)) && input!=nil
            # this covers:
            #    download 'file' from:'site.com/file'
            #    download 'file'  url:'site.com/file'
            the_url = from || url
            file_name = input
        else
            raise <<-HEREDOC.remove_indent
                I'm not sure how you're using the download function.
                Please use one of the following methods:
                    download     'site.com/file'
                    download     'site.com/file', to:'file'
                    download url:'site.com/file', to:'file'
                    download 'file', from:'site.com/file'
                    download 'file',  url:'site.com/file'
            HEREDOC
        end
        FileSys.write(open(URI.encode(the_url)).read, to: file_name)
    end
end
# create an FS alias
FS = FileSys