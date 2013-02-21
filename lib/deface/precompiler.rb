module Deface
  class Precompiler

    extend Deface::TemplateHelper

    def self.precompile
      base_path = Rails.root.join("app/compiled_views")
      # temporarily configures deface env and loads
      # all overrides so we can precompile
      unless Rails.application.config.deface.enabled
        Rails.application.config.deface = Deface::Environment.new
        Rails.application.config.deface.overrides.early_check
        Rails.application.config.deface.overrides.load_all Rails.application
      end

      Rails.application.config.deface.overrides.all.each do |virtual_path,overrides|
        template_path = base_path.join( "#{virtual_path}.html.erb")

        FileUtils.mkdir_p template_path.dirname
        begin
          source = load_template_source(virtual_path.to_s, false, true)
          if source.blank?
            raise "Compiled source was blank for '#{virtual_path}'"
          end
          File.open(template_path, 'w') {|f| f.write source } 
        rescue Exception => e
          puts "Unable to precompile '#{virtual_path}' due to: "
          puts e.message
        end
      end
    end
  end
end
