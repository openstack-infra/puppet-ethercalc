require 'puppet-openstack_infra_spec_helper/spec_helper_acceptance'

describe 'puppet-ethercalc:: manifest', :if => ['debian', 'ubuntu'].include?(os[:family]) do
  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def init_puppet_module
    module_path = File.join(pp_path, 'ethercalc.pp')
    File.read(module_path)
  end

  it 'should work with no errors' do
    apply_manifest(init_puppet_module, catch_failures: true)
  end

  describe 'required packages' do
    describe 'os packages' do
      required_packages = [
        package('curl'),
        package('redis-server'),
      ]

      required_packages.each do |package|
        describe package do
          it { should be_installed }
        end
      end
    end
  end

  describe 'required files' do
    describe file('/opt/ethercalc') do
      it { should be_directory }
    end
  end

  # TODO(ianw): not quite reliable ... possibly need this in a retry
  # loop for a little to let the service start up?

  # describe 'required services' do
  #   describe 'ports are open and services are reachable' do
  #     describe port(8000) do
  #       it { should be_listening }
  #     end

  #     describe command('curl http://localhost:8000 --verbose') do
  #       its(:stdout) { should contain('EtherCalc - Share the URL to your friends') }
  #     end
  #   end
  # end

end
