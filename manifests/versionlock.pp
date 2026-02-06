# @summary Locks package from updates.
#
# @example Sample usage
#   yum::versionlock { 'bash':
#     ensure => present,
#     version => '4.1.2',
#     release => '9.el8',
#     epoch   => 0,
#     arch    => 'noarch',
#   }
#
# @param ensure Specifies if versionlock should be `present`, `absent` or `exclude`.
#
# @param version Version of the package
#
# @param release Release of the package
#
# @param arch Arch of the package
#
# @param epoch Epoch of the package
#
# @param package The package name or package glob
#
# @see https://dnf-plugins-core.readthedocs.io/en/latest/versionlock.html
#
define yum::versionlock (
  Enum['present', 'absent', 'exclude']       $ensure  = 'present',
  Optional[Yum::RpmVersion]                  $version = undef,
  Yum::RpmRelease                            $release = '*',
  Variant[Integer[0], Pattern[/^[1-9]\d*$/]] $epoch   = 0,
  Variant[Yum::RpmArch, Enum['*']]           $arch    = '*',
  Yum::RpmNameGlob                           $package = $title,
) {
  if $ensure in ['present', 'exclude'] and ! $version {
    fail('The version parameter must be set when ensure is present or exclude')
  }

  require yum::plugin::versionlock

  $line_prefix = $ensure ? {
    'exclude' => '!',
    default   => '',
  }

  $_versionlock = "${line_prefix}${name}-${epoch}:${version}-${release}.${arch}"

  unless $ensure == 'absent' {
    concat::fragment { "yum-versionlock-${name}":
      content => "${_versionlock}\n",
      target  => $yum::plugin::versionlock::path,
    }
  }
}
