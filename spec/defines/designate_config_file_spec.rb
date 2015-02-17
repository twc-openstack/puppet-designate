require 'spec_helper'

describe 'designate::config_file' do
  let (:title) { 'config_file' }

  context 'with basic settings' do
    let :params do {
      :file          => 'designate.conf',
      :ensure        => 'present',
      :source_dir    => '/var/designate',
      :link_from_dir => '/tmp/designate',
      } 
    end

    it 'should configure the config_file' do
      should contain_file('/etc/designate/designate.conf').with(
        :ensure  => 'present',
        :source  => ['/var/designate/designate.conf', '/var/designate/designate.conf.sample'],
        :replace => false,
      )
      should contain_file('/tmp/designate/designate.conf').with(
        :ensure => 'link',
        :force  => true,
        :target => '/etc/designate/designate.conf',
      ) 
    end
  end
end
