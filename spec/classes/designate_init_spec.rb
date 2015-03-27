#
# Unit tests for designate::init
#
require 'spec_helper'

describe 'designate' do

  let :params do
    {
      :package_ensure     => 'installed',
      :debug              => 'False',
      :verbose            => 'False',
      :root_helper        => 'sudo designate-rootwrap /etc/designate/rootwrap.conf'
    }
  end

  let :rabbit_params do
    {
      :rabbit_host        => '127.0.0.1',
      :rabbit_port        => 5672,
      :rabbit_userid      => 'guest',
      :rabbit_password    => '',
      :rabbit_virtualhost => '/'
    }
  end

  shared_examples_for 'designate' do

    context 'with rabbit_host parameter' do
      before { params.merge!( rabbit_params ) }
      it_configures 'a designate base installation'
    end

  end

  shared_examples_for 'a designate base installation' do

    it { is_expected.to contain_class('designate::params') }

    it 'configures designate group' do
      is_expected.to contain_group('designate').with(
        :ensure  => 'present',
        :name    => 'designate',
      )
    end

    it 'configures designate user' do
      is_expected.to contain_user('designate').with(
        :ensure  => 'present',
        :name    => 'designate',
        :gid     => 'designate',
        :system  => true,
      )
    end

    it 'configures designate configuration folder' do
      is_expected.to contain_file('/etc/designate/').with(
        :ensure  => 'directory',
        :owner   => 'designate',
        :group   => 'designate',
        :mode    => '0750'
      )
    end

    it 'configures designate configuration file' do
      is_expected.to contain_file('/etc/designate/designate.conf').with(
        :owner   => 'designate',
        :group   => 'designate',
        :mode    => '0640'
      )
    end

    it 'installs designate common package' do
      is_expected.to contain_package('designate-common').with(
        :ensure => 'installed',
        :name   => platform_params[:common_package_name],
      ).that_comes_before('Group[designate]')
    end

    it 'configures debug and verbosity' do
      is_expected.to contain_designate_config('DEFAULT/debug').with_value( params[:debug] )
      is_expected.to contain_designate_config('DEFAULT/verbose').with_value( params[:verbose] )
      is_expected.to contain_designate_config('DEFAULT/root_helper').with_value( params[:root_helper] )
    end

  end

  shared_examples_for 'rabbit without HA support' do

    it 'configures rabbit' do
      is_expected.to contain_designate_config('DEFAULT/rabbit_userid').with_value( params[:rabbit_userid] )
      is_expected.to contain_designate_config('DEFAULT/rabbit_password').with_value( params[:rabbit_password] )
      is_expected.to contain_designate_config('DEFAULT/rabbit_password').with_value( params[:rabbit_password] ).with_secret(true)
      is_expected.to contain_designate_config('DEFAULT/rabbit_virtualhost').with_value( params[:rabbit_virtualhost] )
    end

    it { is_expected.to contain_designate_config('DEFAULT/rabbit_host').with_value( params[:rabbit_host] ) }
    it { is_expected.to contain_designate_config('DEFAULT/rabbit_port').with_value( params[:rabbit_port] ) }

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :common_package_name => 'designate-common' }
    end

    it_configures 'designate'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :common_package_name => 'openstack-designate' }
    end

    it_configures 'designate'
  end

  context 'with custom package name' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :common_package_name => 'designate-common-custom-name' }
    end

    before do
      params.merge!({ :common_package_name => 'designate-common-custom-name' })
    end

    it_configures 'designate'
  end
end
