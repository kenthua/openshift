#!/usr/bin/python
#test
# (c) 2015, ravellosystems
# 
# author zoza
#
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

######################################################################
import sys

try:
    from ravello_sdk import *

except ImportError:
    print "failed=True msg='ravello sdk required for this module'"
    sys.exit(1)



DOCUMENTATION = '''
---
module: ravello_facts
short_description: fqdn list of an application in ravellosystems
description:
	 - will return a fqdn list of exist application hosts with their external services

options:
  username:
     description:
      - ravello username
  password:
    description:
     - ravello password

  name:
    description:
     - application name

  service_name: 
    description:
     - Supplied Service name for list state 
    default: ssh

  filter:
    description:
     - filter for vm state
    default: 'STARTED'

'''

EXAMPLES = '''

# List application example
- local_action:
    module: ravello_facts
    name: 'my-application-name'
    service_name: 'ssh'
    filter: 'STARTED'

'''

# import module snippets
from ansible.module_utils.basic import *
import ansible
import os
import functools
import logging
import io
import datetime
import sys

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
log_capture_string = io.BytesIO()


def main():

    ch = logging.StreamHandler(log_capture_string)
    ch.setLevel(logging.DEBUG)
    ### Optionally add a formatter
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    ch.setFormatter(formatter)

    ### Add the console handler to the logger
    logger.addHandler(ch)    
    module = AnsibleModule(
        argument_spec=dict(
            # for nested babu only
            url=dict(required=False, type='str'),

            username=dict(required=False, type='str'),
            password=dict(required=False, type='str'),

            name=dict(required=True, type='str'),
            filter=dict(default='STARTED', type='str'),
            service_name=dict(default='ssh', type='str'),
        )
    )
    try:
        username = module.params.get('username', os.environ.get('RAVELLO_USERNAME', None)) 
        password = module.params.get('password', os.environ.get('RAVELLO_PASSWORD', None))
        
        client = RavelloClient(username, password, module.params.get('url'))

        list_app(client, module)

    except Exception, e:
        log_contents = log_capture_string.getvalue()
        log_capture_string.close()
        module.fail_json(msg='%s' % e, stdout='%s' % log_contents)


def list_app(client, module):
    try:
        app_name = module.params.get("name")
        app = client.get_application_by_name(app_name)
        
        results = []
        filter = module.params.get("filter")
        for vm in app['deployment']['vms']:
            if vm['state'] != filter:
                continue
            (dest, port, publicIp) = get_list_app_vm_result(vm, module)
            results.append({'host': dest, 'port': port, 'publicIp': publicIp})
        log_contents = log_capture_string.getvalue()
        log_capture_string.close()
        module.exit_json(changed=True, name='%s' % app_name, results='%s' % results,stdout='%s' % log_contents)
    except Exception, e:
        log_contents = log_capture_string.getvalue()
        log_capture_string.close()
        module.fail_json(msg = '%s' % e,stdout='%s' % log_contents)


def is_relevant_external_service(supplied_service, module):
    return supplied_service['name'].lower() == module.params.get('service_name').lower() and supplied_service['external'] == True


def get_list_app_vm_result(vm, module):
    for supplied_service in vm['suppliedServices']:
        if is_relevant_external_service(supplied_service, module):
            for network_connection in vm['networkConnections']:
                if network_connection['ipConfig']['id'] == supplied_service['ipConfigLuid']:
                    dest = network_connection['ipConfig'].get('fqdn')
                    port = int(supplied_service['externalPort'].split(",")[0].split("-")[0])
                    publicIp = network_connection['ipConfig'].get('publicIp')
                    return dest, port, publicIp


main()
