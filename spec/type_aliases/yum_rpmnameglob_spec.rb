require 'spec_helper'

describe 'Yum::RpmnameGlob' do
  it { is_expected.to allow_value('python36-foobar') }
  it { is_expected.to allow_value('openssh-*') }
  it { is_expected.to allow_value('*-client') }
  # confirmed that Name: puppet:agent is not permitted
  # rpmbuild -bs ~/rpmbuild/SPECS/puppet\:agent.spec
  # error: line 28: Illegal char ':' (0x3a) in: Name: puppet:agent
  it { is_expected.not_to allow_values('puppet:agent*') }
end
