source 'https://rubygems.org'

group :default do
  if rack_version = ENV['RACK_VERSION']
    gem 'rack', rack_version
  else
    gem 'rack'
  end
end

group :development do
  gem 'appraisal', '< 1.0', :require => nil
end

gem 'rake', '~> 10.4.2', :group => :test, :require => nil
gem 'rspec', '~> 2.14.1', :group => :test
gem 'jruby-openssl', :group => :test if JRUBY_VERSION < '1.7.0'
