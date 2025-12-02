#
# @summary Installs/removes rpms from local file/URL via yum install command.
#
# @note This type is deprecated as the core `yum` provider now handles the `source`
#       parameter properly; see https://github.com/puppetlabs/puppet/pull/6296.
#       The only use for this type now is the `require_verify` functionality.
#
# @param source file or URL where RPM is available
# @param ensure the desired state of the package
# @param timeout optional timeout for the installation
# @param require_verify optional argument, will reinstall if rpm verify fails
#
# @example Sample usage:
#   yum::install { 'epel-release':
#     ensure => 'present',
#     source => 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm',
#   }
#
define yum::install (
  String                                           $source,
  Enum['present', 'installed', 'absent', 'purged'] $ensure  = 'present',
  Boolean                                          $require_verify = false,
  Optional[Integer]                                $timeout = undef,
) {
  Exec {
    path        => '/bin:/usr/bin:/sbin:/usr/sbin',
    environment => 'LC_ALL=C',
  }

  if $require_verify { 
    case $ensure {
      'present', 'installed', default: {
        exec { "yum-reinstall-${name}":
          command => "yum -y reinstall '${source}'",
          onlyif  => "rpm -q '${name}'",
          unless  => "rpm -V '${name}'",
          timeout => $timeout,
          before  => Exec["yum-install-${name}"],
        }
  
        exec { "yum-install-${name}":
          command => "yum -y install '${source}'",
          unless  => "rpm -q '${name}'",
          timeout => $timeout,
        }
      }
  
      'absent', 'purged': {
        package { $name:
          ensure => $ensure,
        }
      }
    }
  }
  else {
    deprecation('yum::install', 'Other than `$require_verify`, the functionality of this type is now handled via the core `yum` package provider.')

    package { $name:
      ensure => $ensure,
      source => $source,
    }
  }
}
