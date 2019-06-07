require_relative '../atk/os'
require_relative '../atk/remove_indent'
require 'open3'
require 'json'

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

def set_key(yaml_string, key_list, new_value)
    # run the python file with the virtual environment
    stdout_str, stderr_str, status = execute_with_local_python('set_key.py', yaml_string, key_list.to_json, new_value.to_json)
    if not status.success?
        raise "\n\nFailed to set key in yaml file:\n#{stderr_str}"
    end
    return stdout_str
end

def remove_key(yaml_string, key_list)
    # run the python file with the virtual environment
    stdout_str, stderr_str, status = execute_with_local_python('remove_key.py', yaml_string, key_list.to_json)
    if not status.success?
        raise "\n\nFailed to remove key in yaml file:\n#{stderr_str}"
    end
    return stdout_str
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