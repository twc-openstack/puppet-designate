require 'spec_helper'

describe 'designate::binary_link' do
  let (:title) { 'binary_link_test' }

  context 'with basic settings' do
    let :params do {
      :file       => 'foo',
      :source_dir => '/tmp',
      :dest_dir   => '/var',
      } 
    end

    it 'should configure the binary_link' do
      should contain_file('/var/foo').with(
        :ensure => 'link',
        :force  => true,
        :target => '/tmp/foo',
      )
    end
  end
end
