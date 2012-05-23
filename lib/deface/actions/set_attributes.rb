module Deface
  module Actions
    class SetAttributes < AttributeAction
      def execute_for_attribute target_element, name, value
        target_element.remove_attribute(name)
        target_element.remove_attribute("data-erb-#{name}")

        if target_element.attributes.key? name
          target_element.set_attribute name, value.to_s
        else
          target_element.set_attribute "data-erb-#{name}", value.to_s
        end
      end
    end
  end
end