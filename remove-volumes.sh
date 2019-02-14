#!/usr/bin/env python

import yaml

def remove_key_rec(mapping, removeKey):
    mapping.pop(removeKey, None)
    for key, value in mapping.iteritems():
        if type(value) is dict:
          remove_key_rec(value, removeKey)

with open("docker-compose.yml", 'r') as stream:
    try:
        a = yaml.load(stream)
        remove_key_rec(a, 'volumes')
        print(yaml.dump(a, default_flow_style=False))
    except yaml.YAMLError as exc:
        print(exc)



