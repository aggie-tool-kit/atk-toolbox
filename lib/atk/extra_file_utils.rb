require 'etc'
require 'fileutils'
require 'pathname'
require 'open-uri'
require_relative './os'

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
    
    # this is for having docstrings that get their indent removed
    # this is used frequently for multi-line strings and error messages
    # example usage 
    # puts <<-HEREDOC.remove_indent
    # This command does such and such.
    #     this part is extra indented
    # HEREDOC
    def remove_indent
        gsub(/^[ \t]{#{self.match(/^[ \t]*/)[0].length}}/, '')
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
    
    def username
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
        end
        # make sure the "to" path exists
        FileSys.touch_dir(to)
        # perform the copy
        FileUtils.copy_entry(from, to/new_name, preserve, dereference_root, force)
    end

    def self.move(from:nil, to:nil, new_name:"", force: true, noop: nil, verbose: nil, secure: nil)
        if new_name == ""
            raise "\n\nFileSys.move() needs a new_name: argument\nset new_name:nil if you wish the file/folder to keep the same name\ne.g. FileSys.move(from:'place/thing', to:'place', new_name:nil)"
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
    def list_files(path=".")
        Dir.children(path).select {|each| FileSys.file?(each)}
    end
    def list_folders(path=".")
        Dir.children(path).select {|each| FileSys.directory?(each)}
    end
    def ls(path)
        Dir.children(path)
    end
    def pwd
        Dir.pwd
    end
    def cd(path, verbose: false)
        FileUtils.cd(path, verbose: verbose)
    end
    def chdir(path, verbose: false)
        FileUtils.cd(path, verbose: verbose)
    end
    
    # File aliases
    def self.time_access(*args, **kwargs)
        File.atime(*args, **kwargs)
    end
    def self.time_created(*args, **kwargs)
        File.birthtime(*args, **kwargs)
    end
    def self.time_modified(*args, **kwargs)
    end
    def self.dir?(*args, **kwargs)
        File.directory?(*args, **kwargs)
    end
    def self.exists?(*args, **kwargs)
        File.exist?(*args,**kwargs)
    end
    
    # inherit from File
    def self.absolute_path(*args, **kwargs)
        File.absolute_path(*args,**kwargs)
    end
    def self.dirname(*args, **kwargs)
        File.dirname(*args,**kwargs)
    end
    def self.basename(*args, **kwargs)
        File.basename(*args,**kwargs)
    end
    def self.extname(*args, **kwargs)
        File.extname(*args,**kwargs)
    end
    def self.directory?(*args, **kwargs)
        File.directory?(*args,**kwargs)
    end
    def self.file?(*args, **kwargs)
        File.file?(*args,**kwargs)
    end
    def self.empty?(*args, **kwargs)
        File.empty?(*args,**kwargs)
    end
    def self.exist?(*args, **kwargs)
        File.exist?(*args,**kwargs)
    end
    def self.executable?(*args, **kwargs)
        File.executable?(*args,**kwargs)
    end
    def self.symlink?(*args, **kwargs)
        File.symlink?(*args,**kwargs)
    end
    def self.owned?(*args, **kwargs)
        File.owned?(*args,**kwargs)
    end
    def self.pipe?(*args, **kwargs)
        File.pipe?(*args,**kwargs)
    end
    def self.readable?(*args, **kwargs)
        File.readable?(*args,**kwargs)
    end
    def self.size?(*args, **kwargs)
        File.size?(*args,**kwargs)
    end
    def self.socket?(*args, **kwargs)
        File.socket?(*args,**kwargs)
    end
    def self.world_readable?(*args, **kwargs)
        File.world_readable?(*args,**kwargs)
    end
    def self.world_writable?(*args, **kwargs)
        File.world_writable?(*args,**kwargs)
    end
    def self.writable?(*args, **kwargs)
        File.writable?(*args,**kwargs)
    end
    def self.writable_real?(*args, **kwargs)
        File.writable_real?(*args,**kwargs)
    end
    def self.expand_path(*args, **kwargs)
        File.expand_path(*args,**kwargs)
    end
    def self.mkfifo(*args, **kwargs)
        File.mkfifo(*args,**kwargs)
    end
    def self.stat(*args, **kwargs)
        File.stat(*args,**kwargs)
    end
    
    def download(input=nil, from:nil, url:nil, to:nil)
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