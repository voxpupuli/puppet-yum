# Define: yum::repo
#
# This definition realizes a repo from yum::repos
#
# Requires:
#   RPM based system
#
# Sample usage:
#   yum::repo { 'nginx': }
#
define yum::repo (
  String $repository = $title,
) {
  realize(Yumrepo[$repository])
}
