# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'yum::config installonly_limit 1' do
  context 'simple parameters' do
    # Using puppet_apply as a helper
    it 'must work idempotently with no errors' do
      pp = <<-EOS
      yum::config{'installonly_limit':
        ensure   => 2,   # yum (and not dnf) does not like the value 1
      }
      include yum
      EOS
      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes:  true)
    end
  end
end
