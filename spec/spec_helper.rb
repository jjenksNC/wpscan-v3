$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'simplecov'
require 'rspec/its'
require 'webmock/rspec'

if ENV['TRAVIS']
  require 'coveralls'
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
end

SimpleCov.start do
  add_filter '/spec/'
  add_filter 'helper'
end

# See http://betterspecs.org/
RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def redefine_constant(constant, value)
  WPScan.send(:remove_const, constant)
  WPScan.const_set(constant, value)
end

# Dynamic Finders Helpers
def df_expected_all
  YAML.safe_load(File.read(File.join(DYNAMIC_FINDERS_FIXTURES, 'expected.yml')))
end

def df_tested_class_constant(type, slug, finder_class)
  slug_class = slug.tr('-', '_').camelize

  "WPScan::Finders::#{type}::#{slug_class}::#{finder_class}".constantize
end

def df_stubbed_response(fixture, finder_super_class)
  if finder_super_class == 'HeaderPattern'
    { headers: JSON.parse(File.read(fixture)) }
  else
    { body: File.read(fixture) }
  end
end

require 'wpscan'
require 'shared_examples'

# TODO: remove when https://github.com/bblimke/webmock/issues/552 fixed
#       Also remove from CMSScanner
# rubocop:disable all
module WebMock
  module HttpLibAdapters
    class TyphoeusAdapter < HttpLibAdapter
      def self.effective_url(effective_uri)
        effective_uri.port = nil if effective_uri.scheme == 'http' && effective_uri.port == 80
        effective_uri.port = nil if effective_uri.scheme == 'https' && effective_uri.port == 443

        effective_uri.to_s
      end

      def self.generate_typhoeus_response(request_signature, webmock_response)
        response = if webmock_response.should_timeout
                     ::Typhoeus::Response.new(
                       code: 0,
                       status_message: '',
                       body: '',
                       headers: {},
                       return_code: :operation_timedout
                     )
                   else
                     ::Typhoeus::Response.new(
                       code: webmock_response.status[0],
                       status_message: webmock_response.status[1],
                       body: webmock_response.body,
                       headers: webmock_response.headers,
                       effective_url: effective_url(request_signature.uri)
                     )
        end
        response.mock = :webmock
        response
      end
    end
  end
end
# rubocop:enabled all

SPECS                    = Pathname.new(__FILE__).dirname.to_s
FIXTURES                 = File.join(SPECS, 'fixtures')
FINDERS_FIXTURES         = File.join(FIXTURES, 'finders')
DYNAMIC_FINDERS_FIXTURES = File.join(FIXTURES, 'dynamic_finders')

redefine_constant(:DB_DIR, File.join(FIXTURES, 'db'))
