require_relative '../atk/os'
require_relative '../atk/remove_indent'
require 'open3'
require 'json'
require 'yaml'


# how the new parser should work
    # turn every meaninful peice of the yaml file into data that is represented in ruby
        # reference objects instead of actually replacing the reference with the value
        # reference insertion keys instead of actually performing the <<:
        # save the style data (like 0x00 vs 0) to every peice of data
        # save whether or not the data must be single-line 
    # tokenize the yaml recursively with the base case of scalar values
        # HARD: detect when values must be single-line or multiline
            # non-complex keys are single-line
            # anything inside of a JSON-like list or array must be single line
            # everything else I know of can be multiline
    # have both an inline and multiline conversion function for every data type
    # when changing data, convert the new data into a single-line or multiline form based on the parent token
        # if multiline, add the correct amount of indentation

# 
# 
# JSON method
# 
# 
    # example:
        # doc = <<-HEREDOC
        # (dependencies):
        #     python: 3.6.7
        #     gcc: 8.0.0
        # HEREDOC
        # document = YamlEdit.new(string:doc)
        # document["(dependencies)"]["python"].replace_value_with(value: "200")
        # puts document.string
        # # creates:
        # doc = <<-HEREDOC
        # (dependencies):
        #     python: "200"
        #     gcc: 8.0.0
        # HEREDOC

def inject_string(string, middle_part, start_line, start_column, end_line, end_column)
    lines = string.split("\n")
    untouched_begining_lines = lines[0...start_line]
    untouched_ending_lines   = lines[end_line+1..-1]
    middle_lines = []

    before_part = lines[start_line][0...start_column]
    after_part = lines[end_line][end_column..-1]

    return (untouched_begining_lines + [ before_part + middle_part + after_part ] + untouched_ending_lines).join("\n")
end

class YamlEdit
    attr_accessor :string
    
    def initialize(string:nil, file:nil)
        self.init(string:string, file: file)
    end
    
    def init(string:nil, file:nil)
        if string == nil
            string = IO.read(file)
        end
        @root_node = YAML.parse(string).children[0]
        @string = string
        self.attach_to_all_children(@root_node, self)
    end
    
    def attach_to_all_children(node, original_document)
        if node.respond_to?(:children)
            if node.children.is_a?(Array)
                for each in node.children
                    self.attach_to_all_children(each, original_document)
                end
            end
        end
        node.document = original_document
    end
    
    def [](key)
        return @root_node[key]
    end
    
    def save_to(file)
        IO.write(file, @string)
    end
end

class Psych::Nodes::Node
    attr_accessor :document
    def anchor_and_tag(anchor:nil, tag:nil)
        anchor = @anchor if anchor == nil 
        tag = @tag if tag == nil 
        
        string = ""
        if anchor
            string += "&#{anchor} "
        end
        
        if tag
            string += "!#{tag} "
        end
        return string
    end
    
    # saving this for later once the JSON method can be replaced
    def indent_level
        if self.respond_to?(:children)
            if self.children.size > 0
                return self.children[0].start_column
            end
        end
        return 4 + self.start_column
    end
    
    def [](key)
        previous = nil
        # for seq
        if key.is_a?(Integer)
            return self.children[key]
        end
        # for maps
        for each in self.children.reverse
            if each.respond_to?(:value) && each.value == key
                return previous
            end
            previous = each
        end
    end
    
    def replace_value_with(value:nil, literal:nil, anchor: nil, tag:nil)
        if literal == nil
            new_value = value.to_json
        else
            new_value = literal
        end
        middle_part = self.anchor_and_tag(anchor:anchor, tag:tag) + new_value
        new_string = inject_string(@document.string, middle_part, @start_line, @start_column, @end_line, @end_column)
        @document.init( string: new_string )
    end
end

# 
# 
# Old Python Method
# 
# 

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