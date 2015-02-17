require 'spec_helper'

describe 'designate::startup_script' do
  let (:title) { 'my_startup' }

  context 'with source specified' do
    let :params do { :ensure => 'present', :source => 'file://foo' } end
    it 'should configure the startup_script' do
      should contain_designate__startup_script('my_startup').with(
        :ensure => 'present',
        :source => 'file://foo',
      )
    end
  end

  context 'with source not specified on a supported operating system' do
    let :facts do
      { 
        :osfamily        => 'Debian',
        :operatingsystem => 'Ubuntu',
      }
    end

    let :params do { :ensure => 'present' } end
    it 'should configure the startup_script using the default source' do
      should contain_designate__startup_script('my_startup').with(
        :ensure => 'present',
        :source => 'puppet:///modules/designate/my_startup.conf.upstart',
      )
    end
  end

  context 'when an invalid option is supplied to ensure' do
    let :params do { :ensure => 'matt' } end

    it 'fails when ensure is set to something thats not valid' do
      expect {
        should contain_designate__startup_script('my_startup').with_ensure('matt')
      }.to raise_error Puppet::Error, /Unknown value 'matt' for ensure, must be present, absent, auto, or unmanaged/
    end
  end

  context 'on unsupported operating systems with ensure absent' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :params do { :ensure => 'absent' } end

    it 'fails when ensure is absent and no source' do
      expect {
        should contain_designate__startup_script('my_startup').with_ensure('absent')
      }.to raise_error Puppet::Error, /No startup scripts available for*/
    end
  end

  context 'on unsupported operating systems with ensure present' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :params do { :ensure => 'present' } end

    it 'fails when ensure is absent and no source' do
      expect {
        should contain_designate_startup_script('my_startup').with_ensure('present')
      }.to raise_error Puppet::Error, /No startup scripts available for*/
    end
  end
end
