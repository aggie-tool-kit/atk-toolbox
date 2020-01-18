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

module FileSystem
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
    
    def self.write(data, to:nil)
        # make sure the containing folder exists
        FileSystem.makedirs(File.dirname(to))
        # actually download the file
        IO.write(to, data)
    end
    
    def self.append(data, to:nil)
        FileSystem.makedirs(File.dirname(to))
        return open(to, 'a') do |file|
            file << data
        end
    end

    def self.save(value, to:nil, as:nil)
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
            raise "\n\nFileSystem.copy() needs a new_name: argument\nset new_name:nil if you wish the file/folder to keep the same name\ne.g. FileSystem.copy(from:'place/thing', to:'place', new_name:nil)"
        elsif new_name == nil
            new_name = File.basename(from)
        end
        # make sure the "to" path exists
        FileSystem.touch_dir(to)
        # perform the copy
        FileUtils.copy_entry(from, to/new_name, preserve, dereference_root, force)
    end

    def self.move(from:nil, to:nil, new_name:"", force: true, noop: nil, verbose: nil, secure: nil)
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
    
    def self.rename(path, new_name:nil, force: true)
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
    
    def self.touch(path)
        FileSystem.makedirs(File.dirname(path))
        if not FileSystem.file?(path)
            return IO.write(path, "")
        end
    end
    singleton_class.send(:alias_method, :touch_file, :touch)
    singleton_class.send(:alias_method, :new_file, :touch)
    
    def self.touch_dir(path)
        if not FileSystem.directory?(path)
            FileUtils.makedirs(path)
        end
    end
    singleton_class.send(:alias_method, :new_folder, :touch_dir)
    
    # Pathname aliases
    def self.absolute_path?(path)
        Pathname.new(path).absolute?
    end
    singleton_class.send(:alias_method, :is_absolute_path, :absolute_path?)
    singleton_class.send(:alias_method, :abs?, :absolute_path?)
    singleton_class.send(:alias_method, :is_abs, :abs?)
    
    def self.relative_path?(path)
        Pathname.new(path).relative?
    end
    singleton_class.send(:alias_method, :is_relative_path, :relative_path?)
    singleton_class.send(:alias_method, :rel?, :relative_path?)
    singleton_class.send(:alias_method, :is_rel, :rel?)
    
    def self.path_pieces(path)
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
    def self.home
        HOME
    end
    def self.glob(path)
        Dir.glob(path, File::FNM_DOTMATCH) - %w[. ..]
    end
    def self.list_files(path=".")
        Dir.children(path).map{|each| path/each }.select {|each| FileSystem.file?(each)}
    end
    def self.list_folders(path=".")
        Dir.children(path).map{|each| path/each }.select {|each| FileSystem.directory?(each)}
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
    
    def self.join(*args)
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
    def self.folder?(*args)
        File.directory?(*args)
    end
    singleton_class.send(:alias_method, :is_folder, :folder?)
    singleton_class.send(:alias_method, :dir?, :folder?)
    singleton_class.send(:alias_method, :is_dir, :dir?)
    singleton_class.send(:alias_method, :directory?, :folder?)
    singleton_class.send(:alias_method, :is_directory, :directory?)
    
    def self.exists?(*args)
        File.exist?(*args)
    end
    singleton_class.send(:alias_method, :does_exist, :exists?)
    singleton_class.send(:alias_method, :exist?, :exists?)
    
    def self.file?(*args)
        File.file?(*args)
    end
    singleton_class.send(:alias_method, :is_file, :file?)
    
    def self.empty?(*args)
        File.empty?(*args)
    end
    singleton_class.send(:alias_method, :is_empty, :empty?)
    
    def self.executable?(*args)
        File.executable?(*args)
    end
    singleton_class.send(:alias_method, :is_executable, :executable?)
    
    def self.symlink?(*args)
        File.symlink?(*args)
    end
    singleton_class.send(:alias_method, :is_symlink, :symlink?)
    
    def self.owned?(*args)
        File.owned?(*args)
    end
    singleton_class.send(:alias_method, :is_owned, :owned?) 
    
    def self.pipe?(*args)
        File.pipe?(*args)
    end
    singleton_class.send(:alias_method, :is_pipe, :pipe?) 
    
    def self.readable?(*args)
        File.readable?(*args)
    end
    singleton_class.send(:alias_method, :is_readable, :readable?) 
    
    def self.size?(*args)
        if File.directory?(args[0])
            # recursively get the size of the folder
            return Dir.glob(File.join(args[0], '**', '*')).map{ |f| File.size(f) }.inject(:+)
        else
            File.size?(*args)
        end
    end
    singleton_class.send(:alias_method, :size_of, :size?) 
    
    def self.socket?(*args)
        File.socket?(*args)
    end
    singleton_class.send(:alias_method, :is_socket, :socket?) 
    
    def self.world_readable?(*args)
        File.world_readable?(*args)
    end
    singleton_class.send(:alias_method, :is_world_readable, :world_readable?) 
    
    def self.world_writable?(*args)
        File.world_writable?(*args)
    end
    singleton_class.send(:alias_method, :is_world_writable, :world_writable?) 
    
    def self.writable?(*args)
        File.writable?(*args)
    end
    singleton_class.send(:alias_method, :is_writable, :writable?) 
    
    def self.writable_real?(*args)
        File.writable_real?(*args)
    end
    singleton_class.send(:alias_method, :is_writable_real, :writable_real?) 
    
    def self.expand_path(*args)
        File.expand_path(*args)
    end
    def self.mkfifo(*args)
        File.mkfifo(*args)
    end
    def self.stat(*args)
        File.stat(*args)
    end
    
    def self.download(the_url, to:nil)
        require 'open-uri'
        FileSystem.write(open(URI.encode(the_url)).read, to: to)
    end
    
    def self.online?
        require 'open-uri'
        begin
            true if open("http://www.google.com/")
        rescue
            false
        end
    end
    
    class ProfileHelper
        def initialize(unqiue_id)
            function_def = "ProfileHelper.new(unqiue_id)"
            if unqiue_id =~ /\n/
                raise <<-HEREDOC.remove_indent
                    
                    
                    Inside the #{function_def.color_as :code}
                    the unqiue_id contains a newline (\\n)
                    
                    unqiue_id: #{"#{unqiue_id}".inspect}
                    
                    Sadly newlines are not allowed in the unqiue_id due to how they are searched for.
                    Please provide a unqiue_id that doesn't have newlines.
                HEREDOC
            end
            if "#{unqiue_id}".size < 5 
                raise <<-HEREDOC.remove_indent
                    
                    
                    Inside the #{function_def.color_as :code}
                    the unqiue_id is: #{"#{unqiue_id}".inspect}
                    
                    That's not even 5 characters. Come on man, there's going to be problems if the unqiue_id isn't unqiue
                    generate a random number (once), then put the name of the service at the front of that random number
                HEREDOC
            end
            @unqiue_id = unqiue_id
        end
        
        def bash_comment_out
            ->(code) do
                "### #{code}"
            end
        end
        
        def add_to_bash_profile(code)
            uniquely_append(code, HOME/".bash_profile", bash_comment_out)
        end
        
        def add_to_zsh_profile(code)
            uniquely_append(code, HOME/".zprofile", bash_comment_out)
        end
        
        def add_to_bash_rc(code)
            uniquely_append(code, HOME/".bashrc", bash_comment_out)
        end
        
        def add_to_zsh_rc(code)
            uniquely_append(code, HOME/".zshrc", bash_comment_out)
        end
        
        def uniquely_append(string_to_add, location_of_file, comment_out_line)
            _UNQIUE_HELPER = 'fj03498hglkasjdgoghu2904' # dont change this, its a 1-time randomly generated string
            final_string = "\n"
            final_string += comment_out_line["start of ID: #{@unqiue_id} #{_UNQIUE_HELPER}"] + "\n"
            final_string += comment_out_line["NOTE! if you remove this, remove the whole thing (don't leave a dangling start/end comment)"] + "\n"
            final_string += string_to_add + "\n"
            final_string += comment_out_line["end of ID: #{@unqiue_id} #{_UNQIUE_HELPER}"]
            
            # open the existing file if there is one
            file = FS.read(location_of_file) || ""
            # remove any previous versions
            file.gsub!(/### start of ID: (.+) #{_UNQIUE_HELPER}[\s\S]*### end of ID: \1 #{_UNQIUE_HELPER}/) do |match|
                if $1 == @unqiue_id
                    ""
                else
                    match
                end
            end
            # append the the new code at the bottom (highest priority)
            file += final_string
            # overwrite the file
            FS.write(file, to: location_of_file)
        end
    end
end
# create an FS singleton_class.send(:alias_method, :FS = :FileSystem)
FS = FileSystem




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