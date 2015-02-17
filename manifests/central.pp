# == Class designate::central
#
# Configure designate central service
#
# == Parameters
#
# [*package_ensure*]
#  (optional) The state of the package
#  Defaults to 'present'
#
# [*central_package_name*]
#  (optional) Name of the package containing central resources
#  Defaults to central_package_name from designate::params
#
# [*enabled*]
#   (optional) Whether to enable services.
#   Defaults to true
#
# [*service_ensure*]
#  (optional) Whether the designate central service will be running.
#  Defaults to 'running'
#
# [*startup_script_ensure*]
#  (optional) Whether or not the startup script for designate-central should be
#  installed.  Defaults to 'auto'
#  Valid options are: 'absent', 'auto', 'present', and 'unmanaged'. See the
#  designate::startup_script class for details.
#
# [*startup_script_source*]
#  (optional) Source for startup script if enabled
#  Defaults to undef
#
# [*backend_driver*]
#  (optional) Driver used for backend communication (fake, rpc, bind9, powerdns)
#  Defaults to 'bind9'
#
class designate::central (
  $package_ensure        = present,
  $central_package_name  = undef,
  $enabled               = true,
  $service_ensure        = 'running',
  $startup_script_ensure = 'auto',
  $startup_script_source = undef,
  $backend_driver        = 'bind9',
) {
  include ::designate::params

  designate::install { 'designate-central':
    ensure       => $package_ensure,
    package_name => pick($central_package_name, $::designate::params::central_package_name),
  }

  designate::startup_script { 'designate-central':
    ensure => $startup_script_ensure,
    source => $startup_script_source,
  }

  service { 'designate-central':
    ensure     => $service_ensure,
    name       => $::designate::params::central_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => Class['::designate::db'],
    subscribe  => Exec['designate-dbsync']
  }

  designate_config {
    'service:central/backend_driver'         : value => $backend_driver;
  }
}
