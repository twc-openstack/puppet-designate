# == Define: designate::startup_script
#
# Install system startup script for provided service.  By default this class
# will only install startup scripts if you're using virtualenvs.
#
# === Parameters
#
# [*ensure*]
#  (optional) The desired start of the startup script.  Defaults to 'auto',
#  which means that if we're using virtualenvs on a supported operating system,
#  then the script will be installed.  If $ensure is 'present', then the
#  startup will always be installed and will give an error if on an unsupported
#  operating system.  If $ensure is set to 'absent', then any startup scripts
#  with a matching name will be removed.  If $ensure is set to 'unmanaged', the
#  nothing will be done.
#
# [*source*]
#  (optional) file:// or puppet:// URL specifying the source to copy the
#  startup script from.  Defaults to module internal script.
#
define designate::startup_script(
  $ensure = 'auto',
  $source = undef,
) {
  validate_string($ensure)
  $valid_values = [
    '^present$',
    '^absent$',
    '^auto$',
    '^unmanaged$',
  ]
  validate_re($ensure, $valid_values,
    "Unknown value '${ensure}' for ensure, must be present, absent, auto, or unmanaged")

  # If the user specified, do what they asked, unless we're on an unsupported
  # OS.
  #
  # If they didn't specify, and we're on a supported OS and they're using
  # virtualenvs, then assume they want startup scripts, otherwise don't install
  # them.  The idea is that we can provide the dependencies where they make
  # sense and hide the DWIM logic in this type.

  $supported  = $designate::params::startup_supported
  $using_venv = $designate::install_type == 'virtualenv'

  if $ensure == 'present' or $ensure == 'absent' {
    unless $supported or $source {
      fail("No startup scripts available for ${::operatingsystem}")
    }
    $enabled = true
    $ensure_real = $ensure ? {
      'present' => 'file',
      'absent'  => 'absent',
    }
  } elsif $ensure == 'auto' and $using_venv and $supported {
    $enabled = true
    $ensure_real = 'file'
  } else {
    # The user specified 'unmanaged' or didn't specify ($ensure == auto) and
    # we're not using virtualenvs on a supported OS, so don't install startup
    # scripts.
    $enabled = false
  }

  if $enabled {
    $service_suffix = $designate::params::service_suffix
    $service_type   = $designate::params::service_type
    $module_source  = "puppet:///modules/designate/${name}${service_suffix}.${service_type}"
    file { "/etc/init/${name}${service_suffix}":
      ensure => $ensure_real,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => pick($source, $module_source),
    }
  }
}
