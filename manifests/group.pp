#
# @summary This definition installs or removes yum package group.
#
# @param ensure specifies if package group should be present (installed) or absent (purged)
# @param timeout exec timeout for yum groupinstall command
# @param install_options options provided to yum groupinstall command
#
# @example Sample usage:
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
    'present', default: { # just install the yum group and ensure the group is present.
      exec { "yum-groupinstall-${name}":
        command => join(concat(["yum -y group install '${name}'"], $install_options), ' '),
        unless  => "yum grouplist hidden '${name}' | egrep -i '^Installed.+Groups:$'",
        timeout => $timeout,
      }
    }
    'installed': { # install the yum group and re-install if any packages are missing.
      exec { "yum-groupinstall-${name}":
        command => join(concat(["yum -y group install '${name}'"], $install_options), ' '),
        unless  => "test $(yum --assumeno group install '${name}' 2>/dev/null| grep -c '^Install.*Package') -eq 0",
        timeout => $timeout,
      }
    }
    'latest': { # install the yum group and update if any packages are out of date.
      exec { "yum-groupinstall-${name}":
        command => join(concat(["yum -y group install '${name}'"], $install_options), ' '),
        unless  => "test $(yum --assumeno group install '${name}' 2>/dev/null| grep -c -e '^Install.*Package' -e '^Upgrade.*Package') -eq 0",
        timeout => $timeout,
      }
    }
    'absent', 'purged': {
      exec { "yum-groupremove-${name}":
        command => "yum -y groupremove '${name}'",
        onlyif  => "yum grouplist hidden '${name}' | egrep -i '^Installed.+Groups:$'",
        timeout => $timeout,
      }
    }
  }
}
