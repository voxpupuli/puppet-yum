# frozen_string_literal: true

Facter.add(:dnf_version) do
  confine package_provider: 'dnf'
  setcode do
    dnf = Facter::Util::Resolution.which('dnf')
    next unless dnf

    output = Facter::Core::Execution.execute("#{dnf} --version", on_fail: nil)
    match = output&.match(%r{^(?:dnf\d+ version )?(?<full>(?<major>\d+)(?:\.\d+)+)})
    next unless match

    { 'full' => match[:full], 'major' => match[:major] }
  end
end
