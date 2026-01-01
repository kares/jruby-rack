source 'https://rubygems.org'

group :default do
  if rack_version = ENV['RACK_VERSION']
    gem 'rack', rack_version
  else
    gem 'rack', '~> 3.2'
  end
end

group :development do
  gem 'appraisal', require: false
end

gem 'rake', '~> 13.3', group: :test, require: false
gem 'rspec', group: :test, require: false
