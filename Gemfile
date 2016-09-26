source ENV["GEM_SOURCE"] || "https://rubygems.org"

group :test do
  gem "rake"
  gem "puppet", ENV["PUPPET_GEM_VERSION"] || "~> 4.6.0"
  gem "rspec"
  gem "rspec-puppet", :git => "https://github.com/rodjek/rspec-puppet.git"
  gem "puppetlabs_spec_helper"
  gem "metadata-json-lint"
  gem "rspec-puppet-facts"
  gem "ci_reporter_rspec"
  gem "rubocop"
  gem "simplecov"
  gem "simplecov-console"

  gem "puppet-lint-absolute_classname-check"
  gem "puppet-lint-leading_zero-check"
  gem "puppet-lint-trailing_comma-check"
  gem "puppet-lint-version_comparison-check"
  gem "puppet-lint-classes_and_types_beginning_with_digits-check"
  gem "puppet-lint-unquoted_string-check"
  gem "puppet-lint-resource_reference_syntax"
end

group :development do
  gem "travis"
  gem "travis-lint"
  gem "vagrant-wrapper"
  gem "puppet-blacksmith"
end

group :system_tests do
  gem "beaker"
  gem "beaker-rspec"
  gem "beaker-puppet_install_helper"
end
