$source_dir = '/opt/openstack-health'

include ethercalc::redis

class { '::ethercalc': }
