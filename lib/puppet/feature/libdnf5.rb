# frozen_string_literal: true

# True once python3 can import libdnf5
Puppet.features.add(:libdnf5) do
  Puppet::Util::Execution.execute(['python3', '-c', 'import libdnf5'], failonfail: false).exitstatus.zero? || nil
rescue StandardError
  nil
end
