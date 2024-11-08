# Define: yum::group
#
# This definition installs or removes yum package group.
#
# Parameters:
#   [*ensure*]   - specifies if package group should be
#                  present (installed) or absent (purged)
#   [*timeout*]  - exec timeout for yum groupinstall command
#   [*install_options*]  - options provided to yum groupinstall command
#
# Actions:
#
# Requires:
#   RPM based system
#
# Sample usage:
#   yum::group { 'X Window System':
#     ensure  => 'present',
#   }
#
define yum::group (
  Array[String[1]]                                    $install_options = [],
  Enum['present', 'installed', 'latest', 'absent', 'purged'] $ensure   = 'present',
  Optional[Integer] $timeout                                           = undef,
) {
  Exec {
    path        => '/bin:/usr/bin:/sbin:/usr/sbin',
    environment => 'LC_ALL=C',
  }

  case $ensure {
    'present', 'installed', default: {
      exec { "yum-groupinstall-${name}":
        command => join(concat(["yum -y group install '${name}'"], $install_options), ' '),
        unless  => "yum group list hidden '${name}' | egrep -i '^Installed.+Groups:$'",
        timeout => $timeout,
      }
      if $ensure == 'latest' {
        exec { "yum-groupinstall-${name}-latest":
          command => join(concat(["yum -y group install '${name}'"], $install_options), ' '),
          onlyif  => "yum group info '${name}' | egrep '\\s+\\+'",
          timeout => $timeout,
          require => Exec["yum-groupinstall-${name}"],
        }
      }
    }

    'absent', 'purged': {
      exec { "yum-groupremove-${name}":
        command => "yum -y group remove '${name}'",
        onlyif  => "yum group list hidden '${name}' | egrep -i '^Installed.+Groups:$'",
        timeout => $timeout,
      }
    }
  }
}
