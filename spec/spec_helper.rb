require 'rspec'
require 'vcr'

require 'debug-bar'

WP::Config::set_config_root(File.expand_path(File.join(File.dirname(__FILE__),'data')))

VCR.configure do |c|
  c.cassette_library_dir = File.dirname(__FILE__) + '/fixtures/vcr_cassettes'
  c.hook_into :webmock
end
