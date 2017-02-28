require 'rainbow'

module Deface
  module Utils
    module FailureFinder
      def overrides_by_virtual_path(virtual_path)
        begin
          load_template_source(virtual_path, false, true).dup
        rescue Exception => e
          puts "Error processing overrides for :virtual_path => '#{virtual_path}'"
          puts " #{e.message}"
          return nil
        end
        Deface::Override.find(:virtual_path => virtual_path)
      end

      def output_results_by_virtual_path(virtual_path)
        has_failz = 0

        fails = overrides_by_virtual_path(virtual_path)
        return(has_failz += 1) if fails.nil?

        count = fails.group_by{ |o| !o.failure.nil? }
        if count.key?(true)
          has_failz += count[true].count
          puts "#{count[true].count} of #{fails.count} override(s) failed for :virtual_path => '#{virtual_path}'"
        else
          puts "0 of #{fails.count} override(s) failed for :virtual_path => '#{virtual_path}'"
        end

        fails.each do |override|
          if override.failure.nil?
            puts Rainbow(" '#{override.name}' reported no failures").green
          else
            puts Rainbow(" '#{override.name}' #{override.failure}").red
          end
        end

        has_failz
      end
    end
  end
end
