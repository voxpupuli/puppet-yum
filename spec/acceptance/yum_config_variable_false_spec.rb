# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'yum::config variable false' do
  context 'simple parameters' do
    # Using puppet_apply as a helper
    it 'must work idempotently with no errors' do
      pp = <<-EOS
      yum::config{'variable':
        ensure   => false,
      }
      EOS
      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes:  true)
    end
  end
end
