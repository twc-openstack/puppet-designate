# Params
#
class designate::params {
  $dbsync_command          =  'designate-manage database sync'
  $powerdns_dbsync_command =  'designate-manage powerdns sync'
  $state_path              =  '/var/lib/designate'
  # bind path
  $designatepath        = "${state_path}/bind9"
  $designatefile        = "${state_path}/bind9/zones.config"
  # Log dir
  $log_dir             =  '/var/log/designate'
  $client_package_name =  'python-designateclient'

  $venv_base_dir       = '/var/lib/openstack-designate'
  # By default with packages the file contents aren't managed, so the setting
  # for replace doesn't matter.  However for virtualenvs, the files from the
  # source checkout are copied by default.  We'll want to replace most of the
  # config files if they've changed, and leave users the option to override via
  # parameters into the main designate class.
  $config_files  = {
    'api-paste.ini'            => { replace => true  },
    'designate.conf'           => { replace => false },
    'policy.json'              => { replace => true  },
    'rootwrap.conf'            => { replace => true  },
    'rootwrap.d/bind9.filters' => { replace => true  },
  }

  # For virtualenv's we need to symlink the binaries a directory that is in the
  # path.  This is the default for the binaries to link and the place to link
  # them to.
  $binaries = [
    'designate-agent',
    'designate-api',
    'designate-central',
    'designate-manage',
    'designate-mdns',
    'designate-rootwrap',
    'designate-sink',
  ]

  case $::osfamily {
    'RedHat': {
      # package name
      $common_package_name   = 'openstack-designate'
      $api_package_name      = 'openstack-designate-api'
      $central_package_name  = 'openstack-designate-central'
      $agent_package_name    = 'openstack-designate-agent'
      $sink_package_name     = 'openstack-designate-sink'
      # service names
      $agent_service_name   = 'openstack-designate-agent'
      $api_service_name     = 'openstack-designate-api'
      $central_service_name = 'openstack-designate-central'
      $sink_service_name    = 'openstack-designate-sink'
    }
    'Debian': {
      # package name
      $common_package_name   = 'designate-common'
      $api_package_name      = 'designate-api'
      $central_package_name  = 'designate-central'
      $agent_package_name    = 'designate-agent'
      $sink_package_name     = 'designate-sink'
      # service names
      $agent_service_name   = 'designate-agent'
      $api_service_name     = 'designate-api'
      $central_service_name = 'designate-central'
      $sink_service_name    = 'designate-sink'
      case $::operatingsystem {
        'Ubuntu': {
          $startup_supported = true
          $service_type      = 'upstart'
          $service_directory = '/etc/init'
          $service_suffix    = '.conf'
        }
        default: {
          $startup_supported = false
        }
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem")
    }
  }
}
