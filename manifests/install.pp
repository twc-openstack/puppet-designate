# == Define: designate::install
#
# This class will manage the installation of designate software from packages
# or as a Python virtualenv.  It will also manage the config files needed by
# that software, with different policies for packages and virtualenvs.  For
# packages just the permissions on the config files will be managed by default,
# with the assumption that your config files will come from the packages.  For
# virtualenv installations, the config files will be copied from the git tree
# that is checked out by default, but the main config file will only be copied
# if it does not exist.  This behavior can be overridden by providing a
# $config_files hash.
#
# Virtualenv installations are built by cloning from the $git_url, checking out
# the $git_revision, and by default building a virtualenv from the
# requirements.txt contained in the repository.  For production use you will
# normally want to override the requirements.txt and provide one that contains
# pinned module versions, and possibly include information about a local pypi
# mirror in the requirements.txt.
#
# This module explicitly supports provisioning multiple virtualenv based
# installations in order to make upgrades and rollbacks easier.  To take
# advantage of this, you can define additional instances of designate::install
# with the active flag set to false and with different $venv_prefix options.
#
# If using virtualenv based installations it's *strongly* recommended that
# virtualenvs be treated as immutable once created.  Behavior with changing
# requirements.txt or code may not be what you expect, since the existing
# virtualenv will be updated, not rebuilt when requirements.txt or the git
# revision changes.
#
# === Parameters
#
# [*ensure*]
#  (required) Whether or not the package should be removed or installed.
#  Should be 'present', or 'absent'. For package installs, other values
#  such as a version number or 'latest' are also acceptable.
#
# [*install_type*]
#  (optional) Whether or not software should be installed via packages or
#  virtualenvs.  Must be 'package' or 'virtualenv'.  Defaults to 'package',
#
# [*package_name*]
#  (optional) If using package installs, the name of the package to install.
#
# [*primary*]
#  (optional) if set to true, and install_type is 'virtualenv', then the
#  virtualenv will be created.  This is so that this type can be used to
#  install packages in appropriate places, and not need to be surrounded by
#  conditionals.
#
# [*venv_active*]
#  (optional) Whether or not the virtualenv should be made active by managing
#  symlinks into it and restarting services if the links are changed.  Defaults
#  to true.
#
# [*base_dir*]
#  (optional) Directory to put virtualenvs and git working copies in if using
#  virtualenvs.  Defaults to /var/lib/openstack-designate
#
# [*bin_dir*]
#  (optional) Directory to link binaries into if the virtualenv is active.
#  Defaults to '/usr/bin'.
#
# [*binaries*]
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
# [*venv_extra_args*]
#  (optional) Extra arguments that will be passed to `pip install` when
#  creating the virtualenv.
#
# [*git_url*]
#  (optional) Git URL to clone source for virtualenv build.  Required for
#  virtualenv install.
#
# [*git_revision*]
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
define designate::install(
  $ensure,
  $install_type      = undef,

  # Package specific
  $package_name      = undef,

  # Virtualenv specific
  $primary           = false,
  $venv_active       = false,
  $base_dir          = undef,
  $bin_dir           = undef,
  $binaries          = undef,
  $venv_prefix       = undef,
  $venv_requirements = undef,
  $venv_extra_args   = undef,
  $git_url           = undef,
  $git_revision      = undef,

  $config_files      = {},
) {
  include ::designate
  include ::designate::params

  $install_type_real = pick($install_type, $::designate::install_type)

  if $install_type_real == 'package' {
    validate_string($package_name)
    package { $name:
      ensure => $ensure,
      name   => $package_name,
      before => Group['designate'],
      tag    => ['openstack'],
    }

    create_resources(::designate::config_file, $config_files)
    Package<| tag == 'designate'|> -> Designate::Config_file<||>
    Package<| tag == 'designate'|> ~> Service<| tag == 'designate' |>

  } elsif $install_type_real == 'virtualenv' and $primary {
    validate_string($ensure)
    $valid_values = [
      '^present$',
      '^absent$',
    ]
    validate_re($ensure, $valid_values,
      "Unknown value '${ensure}' for ensure, must be present or absent for install_type virtualenv")

    validate_string($git_url)
    validate_string($git_revision)

    $repo_dir = "${base_dir}/${venv_prefix}-git"
    vcsrepo { $repo_dir:
      ensure   => $ensure,
      provider => 'git',
      source   => $git_url,
      revision => $git_revision,
    }

    $req_source = pick($venv_requirements, "file:///${repo_dir}/requirements.txt")
    $req_dest = "${base_dir}/${venv_prefix}-requirements.txt"
    $venv_dir = "${base_dir}/${venv_prefix}-venv"
    $venv_name = "${venv_prefix}-${name}"

    if $ensure == 'present' {
      file { $req_dest:
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => $req_source,
        require => Vcsrepo[$repo_dir],
        before  => Python::Virtualenv[$venv_name],
      }
    } else {
      file { $req_dest:
        ensure => 'absent',
      }
    }

    python::virtualenv { $venv_name:
      ensure         => $ensure,
      venv_dir       => $venv_dir,
      requirements   => $req_dest,
      extra_pip_args => $venv_extra_args,
      owner          => 'designate',
      group          => 'designate',
      require        => User['designate'],
      tag            => ['openstack'],
    }

    if $ensure == "present" {
      # We don't need to ensure these are absent, because destroying the
      # virtualenv will remove them
      python::pip { $venv_name:
        ensure      => 'present',
        pkgname     => 'designate',
        url         => "file://${repo_dir}",
        virtualenv  => $venv_dir,
        owner       => 'designate',
        environment => ['SKIP_PIP_INSTALL=1'],
        install_args => '--no-deps',
        require     => Python::Virtualenv[$venv_name],
        tag         => ['openstack', $venv_name],
      }

      python::pip { "${venv_name}/mysql-python":
        ensure     => 'present',
        pkgname    => 'mysql-python',
        virtualenv => $venv_dir,
        owner      => 'designate',
        require    => Python::Virtualenv[$venv_name],
        tag        => ['openstack', $venv_name],
      }

      Python::Pip<| tag == $venv_name|> -> File<| tag == 'designate_venv_etc' |>

      file { ["${venv_dir}/etc", "${venv_dir}/etc/rootwrap.d"]:
        ensure => 'directory',
        owner  => 'designate',
        group  => 'designate',
        mode   => '0750',
        tag    => ['designate_venv_etc'],
      }
    }


    if $venv_active {
      $config_file_defaults = {
        ensure        => 'file',
        source_dir    => "${repo_dir}/etc/designate",
        link_from_dir => "${venv_dir}/etc",
      }
      create_resources(::designate::config_file, $config_files, $config_file_defaults)
      File<| tag == 'designate_venv_etc' |> -> Designate::Config_File<||>

      designate::binary_link { $binaries:
        source_dir => "${venv_dir}/bin",
        dest_dir   => $bin_dir,
      }
      # Only restart the services if we installed software *and* moved the links
      Designate::Binary_link<||> ~> Service<| tag == 'designate' |>
      Python::Virtualenv[$venv_name] ~> Service<| tag == 'designate' |>
      Python::Pip[$venv_name] ~> Service<| tag == 'designate' |>
    }
  } else {
    # if $install_type_real is true (i.e., not false, undef, etc), assume a bad
    # value was passed in.  Otherwise assume we're being asked not to manage
    # software installs at all.
    if $install_type_real and $primary {
      fail('The install_type parameter must be "package" or "virtualenv"')
    }
  }

}
