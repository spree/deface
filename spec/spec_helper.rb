require 'simplecov'
SimpleCov.start 'rails'
require 'rspec'
require 'active_support'
require 'action_view'
require 'action_controller'
require 'deface'
require 'rails/generators'
# have to manually require following for testing purposes
require 'deface/action_view_extensions'
require 'rails/version'

#adding fake class as it's needed by haml 4.0, don't
#want to have to require the entire rails stack in specs.
module Rails
  class Railtie
    def self.initializer(*args)
    end
  end
end

require 'haml'
require 'slim'
require 'deface/haml_converter'
require 'generators/deface/override_generator'
require 'time'

if defined?(Haml::Options)
  # Haml 3.2 changes the default output format to HTML5
  Haml::Options.defaults[:format] = :xhtml
end

RSpec.configure do |config|
  config.mock_framework = :rspec
end

module ActionView::CompiledTemplates
  #empty module for testing purposes
end

shared_context "mock Rails" do
  before(:each) do
    rails_version = Rails::VERSION::STRING

    # mock rails to keep specs FAST!
    unless defined? Rails
      Rails = double 'Rails'
    end

    Rails.stub :version => rails_version

    Rails.stub :application => double('application')
    Rails.application.stub :config => double('config')
    Rails.application.config.stub :cache_classes => true
    Rails.application.config.stub :deface => ActiveSupport::OrderedOptions.new
    Rails.application.config.deface.enabled = true

    if Rails.version[0..2] == '3.2'
      Rails.application.config.stub :watchable_dirs => {}
    end

    Rails.stub :root => Pathname.new('spec/dummy')

    Rails.stub :logger => double('logger')
    Rails.logger.stub(:error)
    Rails.logger.stub(:warning)
    Rails.logger.stub(:info)
    Rails.logger.stub(:debug)

    Time.stub :zone => double('zone')
    Time.zone.stub(:now).and_return Time.parse('1979-05-25')

    require "haml/template/plugin"
    require 'slim/erb_converter'
  end
end

shared_context "mock Rails.application" do
  include_context "mock Rails"

  before(:each) do
    Rails.application.config.stub :deface => Deface::Environment.new
    Rails.application.config.deface.haml_support = true
    Rails.application.config.deface.slim_support = true
  end
end

# Dummy Deface instance for testing actions / applicator
class Dummy
  extend Deface::Applicator::ClassMethods
  extend Deface::Search::ClassMethods

  attr_reader :parsed_document

  def self.all
    Rails.application.config.deface.overrides.all
  end
end
