require_relative '../atk/os'
require_relative '../atk/remove_indent'
require 'open3'
require 'json'
require 'yaml'

# new parser plans:
    # for each data type
        # have formats
        # have a detect format
        # have an export format
    # styles = {
        #     0 => ANY 
        #     1 => PLAIN 
        #     2 => SINGLE_QUOTED 
        #     3 => DOUBLE_QUOTED 
        #     4 => LITERAL 
        #     5 => FOLDED 
        # }
    # string formats
        # newline joined (pipe)
        # space joined (greater-than)
        # keep one ending newline (pipe or greater-than with nothing)
        # no ending newline (minus sign)
        # all ending newlines (plus sign)
    # types
        # nil
            # => nil
        # boolean
            # => true/false
        # string
            # if unquoted inline possible
                # => unquoted inline
            # else
                # if contains newlines
                # => indented multiline, with modifiers according to trailing newlines
                # else if single quoted is possible
                # => single quote inline
                # else
                # => double quote
        # number
            # 
        # regex?
        # array
            # indented tick marks
        # map
            # indented 
       
        


def execute_with_local_python(python_file_path, *args)
    # save the current directory
    pwd = Dir.pwd
    # change to where this file is
    Dir.chdir __dir__
    # run the python file with the virtual environment
    stdout_str, stderr_str, status = Open3.capture3('python3', python_file_path, *args)
    # change back to the original dir
    Dir.chdir pwd
    return [stdout_str, stderr_str, status]
end

module YAML
    def set_key(yaml_string, key_list, new_value)
        if not key_list.is_a?(Array)
            raise "when using YAML.set_key, the second argument needs to be a list of keys"
        end
        # run the python file with the virtual environment
        stdout_str, stderr_str, status = execute_with_local_python('set_key.py', yaml_string, key_list.to_json, new_value.to_json)
        if not status.success?
            raise "\n\nFailed to set key in yaml file:\n#{stderr_str}"
        end
        return stdout_str
    end

    def remove_key(yaml_string, key_list)
        if not key_list.is_a?(Array)
            raise "when using YAML.remove_key, the second argument needs to be a list of keys"
        end
        # run the python file with the virtual environment
        stdout_str, stderr_str, status = execute_with_local_python('remove_key.py', yaml_string, key_list.to_json)
        if not status.success?
            raise "\n\nFailed to remove key in yaml file:\n#{stderr_str}"
        end
        return stdout_str
    end
    module_function :remove_key, :set_key
end

# yaml_test_string = <<-HEREDOC
# foo:
#     a: 1
#     b: 2
#     list:
#         - 1
#         - 2
#         - 3
# thing:
#     a: 10
# HEREDOC
# puts remove_key(yaml_test_string, ["foo", "list", 2])
# puts set_key(yaml_test_string, ["foo", "c"], 3)