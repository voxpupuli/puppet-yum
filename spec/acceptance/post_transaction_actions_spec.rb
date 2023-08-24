# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'yum::post_transaction_action define' do
  context 'simple parameters' do
    let(:pre_condition) do
      "
        package{ 'vim-enhanced-absent':
          name    => 'vim-enhanced',
          ensure  => 'absent',
        }
      "
    end

    # Using puppet_apply as a helper
    it 'must work idempotently with no errors' do
      pp = <<-EOS
      yum::post_transaction_action{'touch_file':
        key     => 'vim-*',
        command => 'touch /tmp/vim-installed',
      }
      yum::post_transaction_action{'second to check for conflicts':
        key     => 'openssh-*',
        command => 'touch /tmp/openssh-installed',
      }
      # Pick a package that is hopefully not installed.
      package{'vim-enhanced':
        ensure  => 'present',
        require => Yum::Post_transaction_action['touch_file'],
      }
      EOS
      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes:  true)
    end

    describe file('/tmp/vim-installed') do
      it { is_expected.to be_file }
    end
  end
end
