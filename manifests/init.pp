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
  # If set to system will install system package, otherwise
  # we try to choose one based on the host platform
  $nodejs_version   = undef,
) {

  $path = '/usr/local/bin:/usr/bin:/bin'

  # For trusty default to upstart, node 4.x.  For Xenial onwards use
  # node 6.x for updated dependencies and the default systemd service
  # file
  case $::operatingsystem {
    'Ubuntu': {
      if $::operatingsystemrelease <= '14.04' {
        $use_upstart = true
        if ! $nodejs_version {
          $use_nodejs_version = '4.x'
        }
      }
      else {
        if ! $nodejs_version {
          $use_nodejs_version = '6.x'
        }
      }
    }
    default: {
      # TODO(ianw) -- not sure this is a sane default, but it's the
      # way it was...
      if ! $nodejs_version {
        $use_nodejs_version = '4.x'
      } else {
        $use_nodejs_version = $nodejs_version
      }
    }
  }

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

  file { "${base_log_dir}/${ethercalc_user}":
    ensure => directory,
    owner  => $ethercalc_user,
  }

  anchor { 'nodejs-package-install': }

  if ($use_nodejs_version != 'system') {
    class { '::nodejs':
      repo_url_suffix        => $use_nodejs_version,
      legacy_debian_symlinks => false,
      before                 => Anchor['nodejs-package-install'],
    }
  } else {
    package { ['nodejs', 'npm']:
      ensure => present,
      before => Anchor['nodejs-package-install'],
    }
  }

  exec { 'install-ethercalc':
    command => "npm install ethercalc@${ethercalc_version}",
    unless  => "npm ls | grep ethercalc@${ethercalc_version}",
    path    => $path,
    cwd     => $base_install_dir,
    require => Anchor['nodejs-package-install'],
  }

  # TODO(ianw): remove this when trusty is dropped
  if $use_upstart {

    file { '/etc/init/ethercalc.conf':
      ensure  => present,
      content => template('ethercalc/upstart.erb'),
      replace => true,
      owner   => 'root',
      require => Exec['install-ethercalc'],
    }

    file { '/etc/init.d/ethercalc':
      ensure => link,
      target => '/lib/init/upstart-job'
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

  } else {

    # Note logs go to syslog, can maybe change when
    # https://github.com/systemd/systemd/pull/7198 is available
    file { '/etc/systemd/system/ethercalc.service':
      ensure  => present,
      content => template('ethercalc/ethercalc.service.erb'),
      replace => true,
      owner   => 'root',
      require => Exec['install-ethercalc'],
    }

    # This is a hack to make sure that systemd is aware of the new service
    # before we attempt to start it.
    exec { 'ethercalc-systemd-daemon-reload':
      command     => '/bin/systemctl daemon-reload',
      before      => Service['ethercalc'],
      subscribe   => File['/etc/systemd/system/ethercalc.service'],
      refreshonly => true,
    }

    service { 'ethercalc':
      ensure  => running,
      enable  => true,
      require => File['/etc/systemd/system/ethercalc.service'],
    }
  }


}
