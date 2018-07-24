$source_dir = '/opt/openstack-health'

include ethercalc::redis

class { '::ethercalc': }

class { '::ethercalc::apache':
  ssl_cert_file => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  ssl_key_file  => '/etc/ssl/private/ssl-cert-snakeoil.key',
  vhost_name    => 'localhost',
}
