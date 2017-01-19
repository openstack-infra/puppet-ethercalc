# == Class: ethercalc::redis
#
class ethercalc::redis(
  $redis_port       = '6379',
  $redis_max_memory = '1gb',
  $redis_bind       = '127.0.0.1',
  $redis_password   = undef,
  $redis_version    = '2.8.4',
) {
  class { '::redis':
    redis_port       => $redis_port,
    redis_max_memory => $redis_max_memory,
    redis_bind       => $redis_bind,
    redis_password   => $redis_password,
    version          => $redis_version ,
  }
}
