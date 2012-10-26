module Deface
  module Generators
    class OverrideGenerator < Rails::Generators::Base
      desc "Generates deface overrides"
      source_root File.expand_path("../templates", __FILE__)
      class_option :template_engine, :desc => 'Template engine to be invoked (erb or haml).'
      argument :view, :type => :string
      argument :name, :type => :string, :default => 'override'

      def copy_template
        engine = options[:template_engine]
        copy_file "override.html.#{engine}.deface", "app/overrides/#{view}/#{name}.html.#{engine}.deface"
      end
    end
  end
end
