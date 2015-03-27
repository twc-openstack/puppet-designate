# == Class designate::api
#
# Configure designate API service
#
# == Parameters
#
# [*package_ensure*]
#  (optional) The state of the package
#  Defaults to 'present'
#
# [*api_package_name*]
#  (optional) Name of the package containing api resources
#  Defaults to api_package_name from designate::params
#
# [*enabled*]
#   (optional) Whether to enable services.
#   Defaults to true
#
# [*service_ensure*]
#  (optional) Whether the designate api service will be running.
#  Defaults to 'running'
#
# [*startup_script_ensure*]
#  (optional) Whether or not the startup script for designate-api should be
#  installed.  Defaults to 'auto'
#  Valid options are: 'absent', 'auto', 'present', and 'unmanaged'. See the
#  designate::startup_script class for details.
#
# [*startup_script_source*]
#  (optional) Source for startup script if enabled
#  Defaults to undef
#
# [*auth_strategy*]
#  (optional) Authentication strategy to use, can be either "noauth" or "keystone"
#  Defaults to 'noauth'
#
# [*keystone_host*]
#  (optional) Host running auth service.
#  Defaults to '127.0.0.1'
#
# [*keystone_port*]
#  (optional) Port to use for auth service on auth_host.
#  Defaults to '35357'
#
# [*keystone_protocol*]
#  (optional) Protocol to use for auth.
#  Defaults to 'http'
#
# [*keystone_tenant*]
#  (optional) Tenant to authenticate to.
#  Defaults to 'services'
#
# [*keystone_user*]
#  (optional) User to authenticate as with keystone.
#  Defaults to 'designate'
#
# [*keystone_password*]
#  (optional) Password used to authentication.
#  Defaults to false
#
# [*enable_api_v1*]
#  (optional) Enable Designate API Version 1
#  Defaults to true
#
# [*enable_api_v2*]
#  (optional) Enable Designate API Version 2 (experimental)
#  Defaults to false
#
class designate::api (
  $package_ensure             = present,
  $api_package_name           = undef,
  $enabled                    = true,
  $service_ensure             = 'running',
  $startup_script_ensure      = 'auto',
  $startup_script_source      = undef,
  $auth_strategy              = 'noauth',
  $keystone_host              = '127.0.0.1',
  $keystone_port              = '35357',
  $keystone_protocol          = 'http',
  $keystone_tenant            = 'services',
  $keystone_user              = 'designate',
  $keystone_password          = false,
  $enable_api_v1              = true,
  $enable_api_v2              = false,
){
  include ::designate::params

  designate::install { 'designate-api':
    ensure       => $package_ensure,
    package_name => pick($api_package_name, $::designate::params::api_package_name),
  }

  designate::startup_script { 'designate-api':
    ensure => $startup_script_ensure,
    source => $startup_script_source,
  }

  service { 'designate-api':
    ensure     => $service_ensure,
    name       => $::designate::params::api_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => Class['::designate::db'],
    subscribe  => Exec['designate-dbsync']
  }

  # API Service
  designate_config {
    'service:api/auth_strategy'             : value => $auth_strategy;
    'service:api/enable_api_v1'             : value => $enable_api_v1;
    'service:api/enable_api_v2'             : value => $enable_api_v2;
  }

  # Keystone Middleware
  designate_config {
    'keystone_authtoken/auth_host'          : value => $keystone_host;
    'keystone_authtoken/auth_port'          : value => $keystone_port;
    'keystone_authtoken/auth_protocol'      : value => $keystone_protocol;
    'keystone_authtoken/admin_tenant_name'  : value => $keystone_tenant;
    'keystone_authtoken/admin_user'         : value => $keystone_user;
    'keystone_authtoken/admin_password'     : value => $keystone_password, secret => true;
  }

}
