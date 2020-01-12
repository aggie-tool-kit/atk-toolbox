require 'etc'
require 'fileutils'
require 'pathname'
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
            next_string_without_leading_or_trailing_slashes = next_string.gsub(/(^\\|^\/|\\$|\/$)/,"")
            output = self + "\\" + next_string
            # replace all forward slashes with backslashes
            output.gsub(/\//,"\\")
        else
            File.join(self, next_string)
        end
    end
end


FS = FileSystem = Class.new do
    # This is a combination of the FileUtils, File, Pathname, IO, Etc, and Dir classes,
    # along with some other helpful methods
    # It is by-default forceful (dangerous/overwriting)
    # it is made to get things done in a no-nonsense error-free way and to have every pratical tool in one place

    # FUTURE add
        # change_owner
        # set_permissions
        # relative_path_between
        # relative_path_to
        # add a force: true option to most of the commands
        # zip
        # unzip
    
    def write(data, to:nil)
        # make sure the containing folder exists
        FileSystem.makedirs(File.dirname(to))
        # actually download the file
        IO.write(to, data)
    end
    
    def append(data, to:nil)
        FileSystem.makedirs(File.dirname(to))
        return open(to, 'a') do |file|
            file << data
        end
    end

    def save(value, to:nil, as:nil)
        # assume string if as was not given
        if as == nil
            as = :s
        end
        
        # add a special exception for csv files
        case as
        when :csv
            require 'csv'
            FS.write(value.map(&:to_csv).join, to: to)
        else
            require 'json'
            require 'yaml'
            conversion_method_name = "to_#{as}"
            if value.respond_to? conversion_method_name
                # this is like calling `value.to_json`, `value.to_yaml`, or `value.to_csv` but programatically
                string_value = value.public_send(conversion_method_name)
                if not string_value.is_a?(String)
                    raise <<-HEREDOC.remove_indent
                    
                    
                        The FileSystem.save(value, to: #{to.inspect}, as: #{as.inspect}) had a problem.
                        The as: #{as}, gets converted into value.to_#{as}
                        Normally that returns a string that can be saved to a file
                        However, the value.to_#{as} did not return a string.
                        Value is of the #{value.class} class. Add a `to_#{as}` 
                        method to that class that returns a string to get FileSystem.save() working
                    HEREDOC
                end
                FS.write(string_value, to:to)
            else
                raise <<-HEREDOC.remove_indent
                
                
                    The FileSystem.save(value, to: #{to.inspect}, as: #{as.inspect}) had a problem.
                    
                    The as: #{as}, gets converted into value.to_#{as}
                    Normally that returns a string that can be saved to a file
                    However, the value.to_#{as} is not a method for value
                    Value is of the #{value.class} class. Add a `to_#{as}` 
                    method to that class that returns a string to get FileSystem.save() working
                HEREDOC
            end
        end
    end
    
    def read(filepath)
        begin
            return IO.read(filepath)
        rescue Errno::ENOENT => exception
            return nil
        end
    end
    
    def delete(path)
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
    
    def makedirs(path)
        FileUtils.makedirs(path)
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
    
    def copy(from:nil, to:nil, new_name:"", force: true, preserve: false, dereference_root: false)
        if new_name == ""
            raise "\n\nFileSystem.copy() needs a new_name: argument\nset new_name:nil if you wish the file/folder to keep the same name\ne.g. FileSystem.copy(from:'place/thing', to:'place', new_name:nil)"
        elsif new_name == nil
            new_name = File.basename(from)
        end
        # make sure the "to" path exists
        FileSystem.touch_dir(to)
        # perform the copy
        FileUtils.copy_entry(from, to/new_name, preserve, dereference_root, force)
    end

    def move(from:nil, to:nil, new_name:"", force: true, noop: nil, verbose: nil, secure: nil)
        if new_name == ""
            raise "\n\nFileSystem.move() needs a new_name: argument\nset new_name:nil if you wish the file/folder to keep the same name\ne.g. FileSystem.move(from:'place/thing', to:'place', new_name:nil)"
        elsif new_name == nil
            new_name = File.basename(from)
        end
        # make sure the "to" path exists
        FileSystem.touch_dir(to)
        # perform the move
        FileUtils.move(from, to/new_name, force: force, noop: noop, verbose: verbose, secure: secure)
    end
    
    def rename(path, new_name:nil, force: true)
        if File.dirname(new_name) != "."
            raise <<-HEREDOC.remove_indent
                
                
                When using FileSystem.rename(path, new_name)
                    The new_name needs to be a filename, not a file path
                    e.g. "foo.txt" not "a_folder/foo.txt"
                    
                    If you want to move the file, use FileSystem.move(from:nil, to:nil, new_name:"")
            HEREDOC
        end
        to = path/new_name
        # make sure the path is clear
        if force
            FileSystem.delete(to)
        end
        # perform the rename
        File.rename(path, to)
    end
    
    def touch(path)
        FileSystem.makedirs(File.dirname(path))
        if not FileSystem.file?(path)
            return IO.write(path, "")
        end
    end
    alias :touch_file :touch
    alias :new_file :touch
    
    def touch_dir(path)
        if not FileSystem.directory?(path)
            FileUtils.makedirs(path)
        end
    end
    alias :new_folder :touch_dir
    
    # Pathname aliases
    def absolute_path?(path)
        Pathname.new(path).absolute?
    end
    alias :is_absolute_path :absolute_path?
    alias :abs? :absolute_path?
    alias :is_abs :abs?
    
    def relative_path?(path)
        Pathname.new(path).relative?
    end
    alias :is_relative_path :relative_path?
    alias :rel? :relative_path?
    alias :is_rel :rel?
    
    def path_pieces(path)
        # use this function like this:
        # *path, filename, extension = FS.path_pieces('/Users/jeffhykin/Desktop/place1/file1.pdf')
        pieces = Pathname(path).each_filename.to_a
        extname = File.extname(pieces[-1])
        basebasename = pieces[-1][0...(pieces[-1].size - extname.size)]
        # add the root if the path is absolute
        if FileSystem.abs?(path)
            if not OS.is?("windows")
                pieces.unshift('/')
            else
                # FUTURE: eventually make this work for any drive, not just the current drive
                pieces.unshift('\\')
            end
        end
        return [ *pieces[0...-1], basebasename, extname ]
    end
    
    # dir aliases
    def home
        HOME
    end
    def glob(path)
        Dir.glob(path, File::FNM_DOTMATCH) - %w[. ..]
    end
    def list_files(path=".")
        Dir.children(path).map{|each| path/each }.select {|each| FileSystem.file?(each)}
    end
    def list_folders(path=".")
        Dir.children(path).map{|each| path/each }.select {|each| FileSystem.directory?(each)}
    end
    def ls(path=".")
        Dir.children(path)
    end
    def pwd
        Dir.pwd
    end
    def cd(*args, verbose: false)
        if args.size == 0
            args[0] = FS.home
        end
        FileUtils.cd(args[0], verbose: verbose)
    end
    def chdir(*args)
        FS.cd(*args)
    end
    
    # File aliases
    def time_access(*args)
        File.atime(*args)
    end
    def time_created(*args)
        File.birthtime(*args)
    end
    def time_modified(*args)
    end
    
    def join(*args)
        if OS.is?("windows")
            folders_without_leading_or_trailing_slashes = args.map do |each|
                # replace all forward slashes with backslashes
                backslashed_only = each.gsub(/\//,"\\")
                # remove leading/trailing backslashes
                backslashed_only.gsub(/(^\\|^\/|\\$|\/$)/,"")
            end
            # join all of them with backslashes
            folders_without_leading_or_trailing_slashes.join("\\")
        else
            File.join(*args)
        end
    end
    
    # inherit from File
    def absolute_path(*args)
        File.absolute_path(*args)
    end
    def dirname(*args)
        File.dirname(*args)
    end
    def basename(*args)
        File.basename(*args)
    end
    def extname(*args)
        File.extname(*args)
    end
    def folder?(*args)
        File.directory?(*args)
    end
    alias :is_folder :folder?
    alias :dir? :folder?
    alias :is_dir :dir?
    alias :directory? :folder?
    alias :is_directory :directory?
    
    def exists?(*args)
        File.exist?(*args)
    end
    alias :does_exist :exists?
    alias :exist? :exists?
    
    def file?(*args)
        File.file?(*args)
    end
    alias :is_file :file?
    
    def empty?(*args)
        File.empty?(*args)
    end
    alias :is_empty :empty?
    
    def executable?(*args)
        File.executable?(*args)
    end
    alias :is_executable :executable?
    
    def symlink?(*args)
        File.symlink?(*args)
    end
    alias :is_symlink :symlink?
    
    def owned?(*args)
        File.owned?(*args)
    end
    alias :is_owned :owned?
    
    def pipe?(*args)
        File.pipe?(*args)
    end
    alias :is_pipe :pipe?
    
    def readable?(*args)
        File.readable?(*args)
    end
    alias :is_readable :readable?
    
    def size?(*args)
        if File.directory?(args[0])
            # recursively get the size of the folder
            return Dir.glob(File.join(args[0], '**', '*')).map{ |f| File.size(f) }.inject(:+)
        else
            File.size?(*args)
        end
    end
    alias :size_of :size?
    
    def socket?(*args)
        File.socket?(*args)
    end
    alias :is_socket :socket?
    
    def world_readable?(*args)
        File.world_readable?(*args)
    end
    alias :is_world_readable :world_readable?
    
    def world_writable?(*args)
        File.world_writable?(*args)
    end
    alias :is_world_writable :world_writable?
    
    def writable?(*args)
        File.writable?(*args)
    end
    alias :is_writable :writable?
    
    def writable_real?(*args)
        File.writable_real?(*args)
    end
    alias :is_writable_real :writable_real?
    
    def expand_path(*args)
        File.expand_path(*args)
    end
    def mkfifo(*args)
        File.mkfifo(*args)
    end
    def stat(*args)
        File.stat(*args)
    end
    
    def download(the_url, to:nil)
        require 'open-uri'
        FileSystem.write(open(URI.encode(the_url)).read, to: to)
    end
    
    def online?
        require 'open-uri'
        begin
            true if open("http://www.google.com/")
        rescue
            false
        end
    end
end.new


# TODO: add zip/unzip functionality
# spec.add_runtime_dependency 'zip', '~> 2.0', '>= 2.0.2'
# require 'zip'

# class ZipFileGenerator
#     # Initialize with the directory to zip and the location of the output archive.
#     def initialize(input_dir, output_file)
#         @input_dir = input_dir
#         @output_file = output_file
#     end

#     # Zip the input directory.
#     def write
#         entries = Dir.entries(@input_dir) - %w[. ..]

#         Zip::ZipFile.open(@output_file, Zip::ZipFile::CREATE) do |zipfile|
#         write_entries entries, '', zipfile
#         end
#     end

#     private

#     # A helper method to make the recursion work.
#     def write_entries(entries, path, zipfile)
#         entries.each do |e|
#         zipfile_path = path == '' ? e : File.join(path, e)
#         disk_file_path = File.join(@input_dir, zipfile_path)

#         if File.directory? disk_file_path
#             recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
#         else
#             put_into_archive(disk_file_path, zipfile, zipfile_path)
#         end
#         end
#     end

#     def recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
#         zipfile.mkdir zipfile_path
#         subdir = Dir.entries(disk_file_path) - %w[. ..]
#         write_entries subdir, zipfile_path, zipfile
#     end

#     def put_into_archive(disk_file_path, zipfile, zipfile_path)
#         zipfile.add(zipfile_path, disk_file_path)
#     end
# end


# def zip(source, destination=nil)
#     if destination == nil
#         destination = source + ".zip"
#     end
    
#     zip_helper = ZipFileGenerator.new(source, destination)
#     zip_helper.write()
# end