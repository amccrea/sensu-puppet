require 'spec_helper_acceptance'

describe 'sensu::backend class', if: ['base','full'].include?(RSpec.configuration.sensu_mode) do
  backend = hosts_as('sensu-backend')[0]
  agent = hosts_as('sensu-agent')[0]
  context 'backend facts' do
    it 'should work without errors' do
      pp = <<-EOS
      include sensu::backend
      EOS

      if RSpec.configuration.sensu_use_agent
        site_pp = "node 'sensu-backend' { #{pp} }"
        puppetserver = hosts_as('puppetserver')[0]
        create_remote_file(puppetserver, "/etc/puppetlabs/code/environments/production/manifests/site.pp", site_pp)
        on backend, puppet("agent -t --detailed-exitcodes"), acceptable_exit_codes: [0,2]
      else
        apply_manifest_on(backend, pp, :catch_failures => true)
        # Simulate plugin sync
        fact_path = File.join(File.dirname(__FILE__), '../..', 'lib/facter')
        scp_to(backend, fact_path, '/opt/puppetlabs/puppet/cache/lib/')
      end
    end

    it "should have backend facts" do
      version = on(backend, 'facter -p sensu_backend.version').stdout
      expect(version).to match(/^[0-9\.]+$/)
    end

    it "should have sensuctl facts" do
      version = on(backend, 'facter -p sensuctl.version').stdout
      expect(version).to match(/^[0-9\.]+$/)
    end
  end

  context 'agent facts' do
    it 'should work without errors' do
      pp = <<-EOS
      include sensu::agent
      EOS

      if RSpec.configuration.sensu_use_agent
        site_pp = "node 'sensu-backend' { #{pp} }"
        puppetserver = hosts_as('puppetserver')[0]
        create_remote_file(puppetserver, "/etc/puppetlabs/code/environments/production/manifests/site.pp", site_pp)
        on agent, puppet("agent -t --detailed-exitcodes"), acceptable_exit_codes: [0,2]
      else
        apply_manifest_on(agent, pp, :catch_failures => true)
        # Simulate plugin sync
        fact_path = File.join(File.dirname(__FILE__), '../..', 'lib/facter')
        scp_to(agent, fact_path, '/opt/puppetlabs/puppet/cache/lib/')
      end
    end

    it "should have agent facts" do
      version = on(agent, 'facter -p sensu_agent.version').stdout
      expect(version).to match(/^[0-9\.]+$/)
    end
  end
end
