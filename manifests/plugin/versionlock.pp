#
# @summary This class installs versionlock plugin
#
# @param ensure specifies if versionlock should be present or absent
# @param clean specifies if yum clean all should be called after edits. Defaults false.
# @param path filepath for the versionlocks
# @param packages hash of packages to version lock. See `yum::versionlock`
#
# @example Sample usage:
#   class{'yum::plugin::versionlock':
#     ensure      => present,
#     packages    => { 'bash' =>
#       'version' => '4.1.2',
#       'release' => '9.el8.2.*',
#       'epoch'   => '0',
#       'arch'    => 'x86_64',
#     }
#   }
#
class yum::plugin::versionlock (
  Enum['present', 'absent'] $ensure = 'present',
  String                    $path   = '/etc/yum/pluginconf.d/versionlock.list',
  Boolean                   $clean  = false,
  Hash                      $packages = {}
) {
  $pkg_prefix = $facts['os']['release']['major'] ? {
    Variant[Integer[5,5], Enum['5']] => 'yum',
    '8' => 'python3-dnf-plugin',
    '9' => 'python3-dnf-plugin',
    default => 'yum-plugin',
  }
  yum::plugin { 'versionlock':
    ensure     => $ensure,
    pkg_prefix => $pkg_prefix,
  }

  if $ensure == 'present' {
    include yum::clean
    $_clean_notify = $clean ? {
      true  => Exec['yum_clean_all'],
      false => undef,
    }

    concat { $path:
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
      notify => $_clean_notify,
    }

    concat::fragment { 'versionlock_header':
      target  => $path,
      content => "# File managed by puppet\n",
      order   => '01',
    }

    $packages.each | $package_name, $package_params| {
      yum::versionlock { $package_name:
        * => $package_params,
      }
    }

  }
}
