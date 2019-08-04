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

class Reference
end

class InjectionReference
end

class Object
    def to_yaml_literal(previous_format_data)
        return  previous_format_data[:referece] + previous_format_data[:tag] + self.to_yaml
    end
    
    def to_yaml
        return self.to_s
    end
end

class Token
    @@types = [:map, :seq, :set, :scalar,]
    @is_key = nil
    @is_element = nil
    @is_set_element = nil
    @type = nil
    @style = {} # style as taken from the psych node
    @contains = []
    
    def to_s
        if @contains.is_a?(Array)
            string = ""
            for each in @contains
                string += each.to_s
            end
            return string
        elsif @contains.is_a?(String)
            return @contains
        end
    end
end

class YamlEditor
    def initilize(from_string:"", from_filepath:nil)
        if from_filepath != nil
            from_string = IO.read(from_filepath)
        end
        @root_token = self.tokenize(from_string)
        
        # TODO: get the indent amount, or use default indent
    end
    
    def tokenize()
        @original_nodes = YAML.parse(from_string)
        @lines = from_string.split(/\n/)
        # TODO: tokenize the string based on the psych_nodes start and end locations
            # for every psych_node create a token and parse the missing spaces that are not captured by the psych nodes
                # check for complex mappings
                # bundle up the trailing : with the key value
                # bundle up comments with their trailing and/or precending whitespace
                # copy over the psych node information, tags, anchors, styles, etc
    end
    
    # TODO: convert this to a method on Psych::Node
    def self.psych_node_to_value(psych_node)
        # convert most everything normally
            # but convert references into a special reference-object 
            # convert injections <<: into special reference-injection keys
        # allow for tags to be converted to a particular type
    end
    
    def psych_node_for(key_list)
        # TODO
    end
    
    def []=(*args)
        *location, new_value = args
        # if theres an existing element
            # get the token
            # take the new_value, convert it using to_yaml_literal with the style/indent arguments
            # tokenize the newly created yaml value
            # offset each newline within the tokens so that the final indent will match
            # replace the old token with the new token
        # if theres not an existing element
            # get the child-most token that does exist
            # for every missing key
                # if its a number
                    # add nil-element tokens until getting the number value needed
                        # then recurse if theres a subsequent missing key or value
                # if it is anything else
                    # see if to_yaml_key returns a string
                        # if it does, then tokenize it and add the key token to the map token
                        # then recurse if theres a subsequent missing key or value
                    # if not, use to_yaml_literal and wrap it in the complex-mapping syntax
                        # tokenize the complex mapping
                        # offset each newline within the tokens so that the final indent will match
                        # add the token
                        # then recurse if theres a subsequent missing key or value
    end
    
    def get_copy_of(key_list)
        # TODO 
    end
    
    def delete(*key_list)
    end
    
    def keys_for(*key_list)
    end
end


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