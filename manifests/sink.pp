# == Class designate::sink
#
# Configure designate sink service
#
# == Parameters
#
# [*package_ensure*]
#  (optional) The state of the package
#  Defaults to 'present'
#
# [*sink_package_name*]
#  (optional) Name of the package containing sink resources
#  Defaults to sink_package_name from designate::params
#
# [*enabled*]
#   (optional) Whether to enable services.
#   Defaults to true
#
# [*service_ensure*]
#  (optional) Whether the designate sink service will be running.
#  Defaults to 'running'
#
# [*startup_script_ensure*]
#  (optional) Whether or not the startup script for designate-sink should be installed.
#  Defaults to 'auto'
#  Valid options are: 'absent', 'auto', 'present', and 'unmanaged'. See the
#  designate::startup_script class for details.
#
# [*startup_script_source*]
#  (optional) Source for startup script if enabled
#  Defaults to undef
#
class designate::sink (
  $package_ensure        = present,
  $sink_package_name     = undef,
  $enabled               = true,
  $service_ensure        = 'running',
  $startup_script_ensure = 'auto',
  $startup_script_source = undef,
) {
  include ::designate::params

  designate::install { 'designate-sink':
    ensure       => $package_ensure,
    package_name => pick($sink_package_name, $::designate::params::sink_package_name),
  }

  designate::startup_script { 'designate-sink':
    ensure => $startup_script_ensure,
    source => $startup_script_source,
  }

  service { 'designate-sink':
    ensure     => $service_ensure,
    name       => $::designate::params::sink_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }
}
