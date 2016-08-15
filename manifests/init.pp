# = Class: composer
#
# == Parameters:
#
# [*target_dir*]
#   Where to install the composer executable.
#
# [*command_name*]
#   The name of the composer executable.
#
# [*user*]
#   The owner of the composer executable.
#
# [*auto_update*]
#   Whether to run `composer self-update`.
#
# [*version*]
#   Custom composer version.
#
# [*group*]
#   Owner group of the composer executable.
#
# [*download_timeout*]
#   The timeout of the download for wget.
#
# [*phar_location*]
#   Default url for last version.
#
# [*download_mirror*]
#   Alternate url for mirror repo.
#
# == Example:
#
#   include composer
#
#   class { 'composer':
#     'target_dir'   => '/usr/local/bin',
#     'user'         => 'root',
#     'command_name' => 'composer',
#     'auto_update'  => true
#   }
#
class composer (
  $target_dir       = $composer::params::target_dir,
  $command_name     = $composer::params::command_name,
  $user             = $composer::params::user,
  $auto_update      = false,
  $version          = $composer::params::version,
  $group            = undef,
  $download_timeout = '0',
  $phar_location    = $composer::params::phar_location,
  $download_mirror  = $composer::params::download_mirror,
) inherits composer::params {

  validate_string($target_dir)
  validate_string($command_name)
  validate_string($user)
  validate_bool($auto_update)
  validate_string($version)
  validate_string($group)

  ensure_packages(['wget'])
  include composer::params

  $target = $version ? {
    undef   => $phar_location,
    default => "${download_mirror}/${version}/composer.phar"
  }

  $composer_full_path = "${target_dir}/${command_name}"
  exec { 'composer-install':
    command => "/usr/bin/wget -O ${composer_full_path} ${target}",
    user    => $user,
    creates => $composer_full_path,
    timeout => $download_timeout,
    require => Package['wget'],
  }

  file { "${target_dir}/${command_name}":
    ensure  => file,
    owner   => $user,
    mode    => '0755',
    group   => $group,
    require => Exec['composer-install'],
  }

  if $auto_update {
    exec { 'composer-update':
      command     => "${composer_full_path} self-update",
      environment => [ "COMPOSER_HOME=${target_dir}" ],
      user        => $user,
      require     => File["${target_dir}/${command_name}"],
    }
  }
}
