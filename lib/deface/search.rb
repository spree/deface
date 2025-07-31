# frozen_string_literal: true

module Deface
  module Search
    module ClassMethods
      VIRTUAL_PATH_CLEANUP_REGEXES = [
        /^\//, # starting with a slash
        /\.\w+\z/ # ending with a file extension
      ].freeze

      # Finds all applicable overrides for supplied template
      def find(details)
        return [] if self.all.empty? || details.empty?

        virtual_path = details[:virtual_path].dup
        return [] if virtual_path.nil?

        VIRTUAL_PATH_CLEANUP_REGEXES.each { |regex| virtual_path.gsub!(regex, '') }

        result = self.all[virtual_path.to_sym]&.values&.flatten || []
        result.compact!
        result.sort_by!(&:sequence)
        result
      end

      # Finds all overrides that are using a template / parital as there source
      def find_using(virtual_path)
        self.all.map do |key, overrides_by_name|
          overrides_by_name.values.select do |override|
            [:template, :partial].include?(override.source_argument) && override.args[override.source_argument] == virtual_path
          end
        end.flatten
      end
    end
  end
end
