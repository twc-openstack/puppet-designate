# == Class designate
#
# Configure designate service
#
# == Parameters
#
# [*install_type*]
#  (optional) Whether or not to install designate via packages, or as a Python
#  virtualenv.  Must be either 'package' or 'virtualenv'. Defaults to
#  'package'.
#
# [*install_ensure*]
#  (optional) The state of the package or virtualenv
#  Defaults to 'present'
#
# [*common_package_name*]
#  (optional) Name of the package containing shared resources
#  Defaults to common_package_name from designate::params
#
# [*venv_active*]
#  (optional) Whether or not the virtualenv should be made active by managing
#  symlinks into it and restarting services if the links are changed.  Defaults
#  to true.
#
# [*venv_base_dir*]
#  (optional) Directory to put virtualenvs and git working copies in if using
#  virtualenvs.  Defaults to /var/lib/openstack-designate
#
# [*venv_bin_dir*]
#  (optional) Directory to link binaries into if the virtualenv is active.
#  Defaults to '/usr/bin'.
#
# [*venv_binaries*]
#  (optional) Array of binaries to link from virtualenv directory to
#  $venv_bin_dir if the virtualenv is active.  Defaults to
#  $::designate::params::binaries.
#
# [*venv_prefix*]
#  (optional) Prefix to give to git and virtualenv directories if path is not
#  explicitly provided.  This can be specified to provide more meaningful
#  names, or to have multiple virtualenvs installed at the same time.  Defaults
#  to 'designate'.
#
# [*venv_requirements*]
#  (optional) Python requirements.txt to pass to pip when populating the
#  virtualenv.  Defaults to the requirements.txt in the cloned repository.
#
# [*venv_git_url*]
#  (optional) Git URL to clone source for virtualenv build.  Required for
#  virtualenv install.
#
# [*venv_git_revision*]
#  (optional) Git revision to checkout for virtualenv build.  Required for
#  virtualenv install.
#
# [*config_files*]
#  (optional) Hash of filenames and parameters to the designate::config_file
#  defined type.  Filenames should be relative to /etc/designate.  For package
#  installs only permissions will be managed.  For virtualenv installs example
#  config files can be copied from the source tree, or provided by the user.
#  Defaults to $::designate::params::config_files
#
# [*service_ensure*]
#  (optional) Whether the designate-common package will be present..
#  Defaults to 'present'
#
# [*debug*]
#   (optional) should the daemons log debug messages.
#   Defaults to 'false'
#
# [*verbose*]
#   (optional) should the daemons log verbose messages.
#   Defaults to 'false'
#
# [*root_helper*]
#   (optional) Command for designate rootwrap helper.
#   Defaults to 'sudo designate-rootwrap /etc/designate/rootwrap.conf'.
#
# [*rabbit_host*]
#   (optional) Location of rabbitmq installation.
#   Defaults to '127.0.0.1'
#
# [*rabbit_port*]
#   (optional) Port for rabbitmq instance.
#   Defaults to '5672'
#
# [*rabbit_password*]
#   (optional) Password used to connect to rabbitmq.
#   Defaults to 'guest'
#
# [*rabbit_userid*]
#   (optional) User used to connect to rabbitmq.
#   Defaults to 'guest'
#
# [*rabbit_virtualhost*]
#   (optional) The RabbitMQ virtual host.
#   Defaults to '/'
#
# [*package_ensure*]
#  (optional) DEPRECATED, replaced by install_ensure
#
class designate(
  $install_type         = 'package',
  $install_ensure       = present,
  $common_package_name  = undef,

  $venv_dir             = undef,
  $venv_bin_dir         = '/usr/bin',
  $venv_binaries        = undef,
  $venv_git_url         = undef,
  $venv_git_revision    = undef,
  $venv_prefix          = 'designate',
  $venv_requirements    = undef,
  $venv_active          = true,

  $config_files         = undef,

  $verbose              = false,
  $debug                = false,
  $root_helper          = 'sudo designate-rootwrap /etc/designate/rootwrap.conf',
  $rabbit_host          = '127.0.0.1',
  $rabbit_port          = '5672',
  $rabbit_userid        = 'guest',
  $rabbit_password      = '',
  $rabbit_virtualhost   = '/',

  # DEPRECATED
  $package_ensure       = undef,
) {

  include ::designate::params

  if $install_type != 'package' and $install_type != 'virtualenv' {
    fail('install_type parameter must be either "package" or "virtualenv"')
  }

  if $package_ensure {
    warning('package_ensure parameter is now deprecated, use install_ensure instead.')
  }

  designate::install { 'designate-common':
    ensure            => pick($package_ensure, $install_ensure),
    install_type      => $install_type,
    package_name      => pick($common_package_name, $::designate::params::common_package_name),
    primary           => true,
    venv_active       => $venv_active,
    base_dir          => pick($venv_base_dir, $::designate::params::venv_base_dir),
    bin_dir           => pick($venv_bin_dir, $::designate::params::bin_dir),
    binaries          => pick($venv_binaries, $::designate::params::binaries),
    venv_prefix       => $venv_prefix,
    venv_requirements => $venv_requirements,
    git_url           => $venv_git_url,
    git_revision      => $venv_git_revision,
    config_files      => pick($config_files, $::designate::params::config_files),
  }

  user { 'designate':
    ensure => 'present',
    name   => 'designate',
    gid    => 'designate',
    system => true,
  }

  group { 'designate':
    ensure => 'present',
    name   => 'designate',
  }

  $managed_dirs = [
    '/etc/designate',
    '/etc/designate/rootwrap.d',
    $::designate::params::log_dir,
  ]
  file { $managed_dirs:
    ensure => directory,
    owner  => 'designate',
    group  => 'designate',
    mode   => '0750',
  }

  Designate::Install<||> -> Designate_config<||>
  Designate_config<||> ~> Service<| tag == 'designate' |>
  Designate::Startup_script<||> ~> Service<| tag == 'designate' |>

  designate_config {
    'DEFAULT/rabbit_host'            : value => $rabbit_host;
    'DEFAULT/rabbit_port'            : value => $rabbit_port;
    'DEFAULT/rabbit_hosts'           : value => "${rabbit_host}:${rabbit_port}";
    'DEFAULT/rabbit_userid'          : value => $rabbit_userid;
    'DEFAULT/rabbit_password'        : value => $rabbit_password, secret => true;
    'DEFAULT/rabbit_virtualhost'     : value => $rabbit_virtualhost;
  }

  # default setting
  designate_config {
    'DEFAULT/debug'                  : value => $debug;
    'DEFAULT/verbose'                : value => $verbose;
    'DEFAULT/root_helper'            : value => $root_helper;
    'DEFAULT/logdir'                 : value => $::designate::params::log_dir;
    'DEFAULT/state_path'             : value => $::designate::params::state_path;
  }

}
