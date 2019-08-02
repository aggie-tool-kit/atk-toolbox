import ruamel.yaml
import regex as re
import json
import sys

yaml_string   = sys.argv[1]
json_key_list = sys.argv[2]
new_key_value = sys.argv[3]


# a tool from https://stackoverflow.com/questions/14692690/access-nested-dictionary-path-via-a-list-of-keys
from functools import reduce  # forward compatibility for Python 3
import operator
def get_by_path(data, path):
    """Access a nested object in data by item sequence."""
    return reduce(operator.getitem, path, data)

def set_by_path(data, path, value):
    """Set a value in a nested object in data by item sequence."""
    get_by_path(data, path[:-1])[path[-1]] = value

# detect the indent
indent_match = re.search(r'^ +', yaml_string, flags=re.MULTILINE)
if indent_match == None:
    indent = 4
else:
    indent = len(indent_match[0])

# parse the yaml
data = ruamel.yaml.round_trip_load(yaml_string)
# parse the path
path_to_element = json.loads(json_key_list)
# parse the new value
new_value = json.loads(new_key_value)
# set the value
set_by_path(data, path_to_element, new_value)
# output the data
print(ruamel.yaml.round_trip_dump(data, indent=indent, block_seq_indent=indent, width=float("Infinity")))