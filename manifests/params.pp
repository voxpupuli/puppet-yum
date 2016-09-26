# == Class yum::params
#
# This class is meant to be called from yum.
# It sets variables according to platform.
#
class yum::params {
  case $::osfamily {
    'redhat': {
      $keepcache = false
      $debuglevel = 2
      $exactarch = true
      $obsoletes = true
      $gpgcheck = true
      $installonly_limit = 5
      $keep_kernel_devel = false
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
