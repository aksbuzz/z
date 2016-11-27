#!/usr/bin/python

import sys
import yaml
import json

yaml_str = open(sys.argv[1]).read()
for data in yaml.load_all(yaml_str):
    json_str = json.dumps(data, sort_keys=True, indent=2)
    print(json_str)
