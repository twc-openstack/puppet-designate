require 'spec_helper'

describe 'designate::install' do
  let (:title) { 'install_test' }

  context 'when install type is package' do
    let :facts do { :osfamily => 'Debian', :operatingsystem => 'Ubuntu', } end
    let :params do { :ensure => 'latest', :install_type => 'package', :package_name => 'designate' } end

    it 'installs the package' do
      should contain_package('install_test').with(
        :name   => 'designate',
        :ensure => 'latest',
      )
    end
  end

  context 'when an invalid option is supplied to ensure and install_type is virtualenv' do
    let :facts do { :osfamily => 'Debian', :operatingsystem => 'Ubuntu', } end
    let :params do { :ensure => 'matt', :install_type => 'virtualenv', :primary => true } end

    it 'fails when ensure is set to something thats not valid for virtualenvs' do
      expect {
        should contain_designate__install('install_test').with_ensure('matt')
      }.to raise_error Puppet::Error, /Unknown value 'matt' for ensure, must be present or absent/
    end
  end

  context 'when a virtualenv is installed and active' do
    let :facts do { :osfamily => 'Debian', :operatingsystem => 'Ubuntu', } end
    let :params do { 
      :ensure       => 'present', 
      :install_type => 'virtualenv', 
      :primary      => true,
      :repo_dir     => '/tmp/foo',
      :git_url      => 'git://example.com',
      :git_revision => '2.0',
      :venv_prefix  => 'pre',
      :venv_dir     => '/var/myenv',
      :venv_active  => true,
    } end

    it 'sets up a vcsrepo' do
      should contain_vcsrepo('/tmp/foo').with(
        :ensure   => 'present',
        :source   => 'git://example.com',
        :revision => '2.0',
        :provider => 'git',
      )
    end

    it 'sets up a virtualenv' do
      should contain_python__virtualenv('pre-install_test').with(
        :ensure       => 'present',
        :venv_dir     => '/var/myenv',
        :requirements => '/tmp/foo/requirements.txt',
        :owner        => 'designate',
        :group        => 'designate',
        :tag          => ['openstack'],
      )
    end

    it 'sets up pip' do
      should contain_python__pip('pre-install_test').with(
        :ensure     => 'present',
        :pkgname    => 'designate',
        :url        => 'file:///tmp/foo',
        :virtualenv => '/var/myenv',
        :owner      => 'designate',
        :tag        => ['openstack', 'pre-install_test'],
      )
    end

    it 'sets up pip for mysql-python' do
      should contain_python__pip('pre-install_test/mysql-python').with(
        :ensure     => 'present',
        :pkgname    => 'mysql-python',
        :virtualenv => '/var/myenv',
        :owner      => 'designate',
        :tag        => ['openstack', 'pre-install_test'],
      )
    end

    it 'sets up config directories' do
      should contain_file('/var/myenv/etc').with(
        :ensure   => 'directory',
        :owner    => 'designate',
        :group    => 'designate',
        :mode     => '0750',
        :tag      => ['designate_venv_etc'],
      )
      should contain_file('/var/myenv/etc/rootwrap.d').with(
        :ensure   => 'directory',
        :owner    => 'designate',
        :group    => 'designate',
        :mode     => '0750',
        :tag      => ['designate_venv_etc'],
      )
    end

#    it 'sets up a binary link since the virtualenv is active' do

  end
end
