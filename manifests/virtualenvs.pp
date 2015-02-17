class designate::virtualenvs(
  $config   = {},
  $defaults = {}
) {
  include ::designate
  include ::designate::params

  $config_files = pick($::designate::config_files, $::designate::params::config_files)
  $internal_defaults = {
    ensure       => 'present',
    install_type => 'virtualenv',
    primary      => true,
    base_dir     => pick($::designate::venv_base_dir, $::designate::params::venv_base_dir),
    bin_dir      => pick($::designate::venv_bin_dir, $::designate::params::bin_dir),
    binaries     => pick($::designate::venv_binaries, $::designate::params::binaries),
    config_files => pick($::designate::config_files, $::designate::params::config_files)
  }
  $defaults_real = merge($internal_defaults, $defaults)
  create_resources('::designate::install', $config, $defaults_real)
}
