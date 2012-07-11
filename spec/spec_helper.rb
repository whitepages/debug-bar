require 'rspec'
#require 'vcr'

require 'debug-bar'

#WP::Config::set_config_root(File.expand_path(File.join(File.dirname(__FILE__),'data')))
#
#VCR.configure do |c|
#  c.cassette_library_dir = File.dirname(__FILE__) + '/fixtures/vcr_cassettes'
#  c.hook_into :webmock
#end

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f}

# Require ruby-debugger if it is available, otherwise don't.
begin
  require 'ruby-debugger'
rescue LoadError
end
