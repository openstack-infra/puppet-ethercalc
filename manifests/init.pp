# == Class: ethercalc
#
# Class to install ethercalc.
#
# To use ethercalc you will want the following includes:
# include ethercalc
# include ethercalc::redis # necessary to use mysql as the backend
# include ethercalc::site # configures ethercalc instance
# include ethercalc::apache # will add reverse proxy on localhost
# The defaults for all the classes should just work (tm)
#
#
class ethercalc (
  $base_install_dir = '/opt/ethercalc',
  $base_log_dir     = '/var/log',
  $ethercalc_user   = 'ethercalc',
  $ethercalc_version= '0.20161220.1',
  # If set to system will install system package.
  $nodejs_version   = 'node_4.x',
) {

  $path = '/usr/local/bin:/usr/bin:/bin'

  group { $ethercalc_user:
    ensure => present,
  }

  user { $ethercalc_user:
    shell   => '/usr/sbin/nologin',
    home    => $base_install_dir,
    system  => true,
    gid     => $ethercalc_user,
    require => Group[$ethercalc_user],
  }

  file { $base_install_dir:
    ensure => directory,
    owner  => $ethercalc_user,
    group  => $ethercalc_user,
    mode   => '0664',
  }

  if !defined(Package['curl']) {
    package { 'curl':
      ensure => present,
    }
  }

  anchor { 'nodejs-package-install': }

  if ($nodejs_version != 'system') {
    class { '::nodejs':
      repo_url_suffix => $nodejs_version,
      before          => Anchor['nodejs-package-install'],
    }
  } else {
    package { ['nodejs', 'npm']:
      ensure => present,
      before => Anchor['nodejs-package-install'],
    }
  }

  file { '/usr/local/bin/node':
    ensure  => link,
    target  => '/usr/bin/nodejs',
    require => Anchor['nodejs-package-install'],
    before  => Anchor['nodejs-anchor'],
  }

  anchor { 'nodejs-anchor': }

  exec { 'install-ethercalc':
    command => "npm install ethercalc@${ethercalc_version}",
    unless  => "npm ls | grep ethercalc@${ethercalc_version}",
    path    => $path,
    cwd     => $base_install_dir,
    require => Anchor['nodejs-anchor'],
  }

  file { '/etc/init/ethercalc.conf':
    ensure  => present,
    content => template('ethercalc/upstart.erb'),
    replace => true,
    owner   => 'root',
  }

  file { '/etc/init.d/ethercalc':
    ensure => link,
    target => '/lib/init/upstart-job',
  }

  file { "${base_log_dir}/${ethercalc_user}":
    ensure => directory,
    owner  => $ethercalc_user,
  }

  service { 'ethercalc':
    ensure  => running,
    enable  => true,
    require => File['/etc/init/ethercalc.conf'],
  }

  include ::logrotate
  logrotate::file { 'ethercalc_error':
    log     => "${base_log_dir}/${ethercalc_user}/error.log",
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => Service['ethercalc'],
  }

  logrotate::file { 'ethercalc_access':
    log     => "${base_log_dir}/${ethercalc_user}/access.log",
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => Service['ethercalc'],
  }
}
