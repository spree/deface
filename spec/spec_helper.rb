require 'simplecov'
SimpleCov.start 'rails'
require 'rspec'
require 'active_support'
require 'deface'
require 'rails/generators'
# have to manually require following for testing purposes
require 'deface/action_view_extensions'
require 'rails/version'
require 'pry'

#adding fake class as it's needed by haml 4.0, don't
#want to have to require the entire rails stack in specs.
module Rails
  class Railtie
    def self.initializer(*args)
    end
  end
end

begin
  I18n.enforce_available_locales = false
rescue
  #shut the hell up
end

require 'haml'
require 'deface/haml_converter'

require 'slim'
require 'deface/slim_converter'
require 'generators/deface/override_generator'
require 'time'

if defined?(Haml::Options)
  # Haml 3.2 changes the default output format to HTML5
  Haml::Options.defaults[:format] = :xhtml
end

RSpec.configure do |config|
  config.mock_framework = :rspec
end

if Deface.before_rails_6?
  module ActionView::CompiledTemplates
    #empty module for testing purposes
  end
else
  class ActionDispatch::DebugView
    #empty module for testing purposes
  end
end

shared_context "mock Rails" do
  before(:each) do
    rails_version = Rails::VERSION::STRING

    # mock rails to keep specs FAST!
    unless defined? Rails
      Rails = double 'Rails'
    end

    allow(Rails).to receive(:version).and_return rails_version

    allow(Rails).to receive(:application).and_return double('application')
    allow(Rails.application).to receive(:config).and_return double('config')
    allow(Rails.application.config).to receive(:cache_classes).and_return true
    allow(Rails.application.config).to receive(:deface).and_return ActiveSupport::OrderedOptions.new
    Rails.application.config.deface.enabled = true

    allow(Rails.application.config).to receive(:watchable_dirs).and_return({})

    allow(Rails).to receive(:root).and_return Pathname.new('spec/dummy')

    allow(Rails).to receive(:logger).and_return double('logger')
    allow(Rails.logger).to receive :error
    allow(Rails.logger).to receive :warning
    allow(Rails.logger).to receive :info
    allow(Rails.logger).to receive :debug

    allow(Time).to receive(:zone).and_return double('zone')
    allow(Time.zone).to receive(:now).and_return Time.parse('1979-05-25')

    require "haml/template"
    require 'slim/erb_converter'
  end
end

shared_context "mock Rails.application" do
  include_context "mock Rails"

  before(:each) do
    allow(Rails.application.config).to receive(:deface).and_return Deface::Environment.new
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
