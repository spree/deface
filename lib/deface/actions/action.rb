module Deface
  module Actions
    class Action
      def initialize options = {}
      end

      class << self
        def desired_action? name
          class_name = self.name.split('::').last.gsub(/(.)([A-Z])/,'\1_\2').downcase
          class_name == name.to_s
        end
      end

      def range_compatible?
        false
      end
    end
  end
end