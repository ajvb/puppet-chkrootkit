source 'https://rubygems.org'

group :rake, :test do
  gem 'puppetlabs_spec_helper', '>=0.8.2', :require => false
#  gem 'rspec-puppet-augeas', '>=0.4.0', :require => false
  gem 'rspec-puppet-augeas', :git => 'git://github.com/mmarod/rspec-puppet-augeas.git', :branch => 'change-puppet-user'
end

group :rake do
  gem 'rspec-puppet', :git => 'git://github.com/joshcooper/rspec-puppet.git', :branch => 'dont-set-libdir'
  gem 'rake',         '>=0.9.2.2'
  gem 'puppet-lint',  '>=1.0.1'
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

