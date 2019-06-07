import ruamel.yaml
import json
import sys

yaml_string   = sys.argv[1]
json_key_list = sys.argv[2]

# a tool from https://stackoverflow.com/questions/14692690/access-nested-dictionary-path-via-a-list-of-keys
from functools import reduce  # forward compatibility for Python 3
import operator
def get_by_path(data, path):
    """Access a nested object in data by item sequence."""
    return reduce(operator.getitem, path, data)

def set_by_path(data, path, value):
    """Set a value in a nested object in data by item sequence."""
    get_by_path(data, path[:-1])[path[-1]] = value


# parse the yaml
data = ruamel.yaml.round_trip_load(yaml_string)
# parse the path
path_to_element = json.loads(json_key_list)
# get the parent element
path_element = get_by_path(data, path_to_element[:-1])
# remove the key
del path_element[path_to_element[-1]]
# output the data
print(ruamel.yaml.round_trip_dump(data))