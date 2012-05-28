module Deface
  module Actions
    class AddToAttributes < AttributeAction
      def execute_for_attribute(target_element, name, value)
        if target_element.attributes.key?(name)
          target_element.set_attribute(name, target_element.attributes[name].value << " #{value}")
        elsif target_element.attributes.key?("data-erb-#{name}")
          target_element.set_attribute("data-erb-#{name}", target_element.attributes["data-erb-#{name}"].value << " #{value}")
        else
          target_element.set_attribute("data-erb-#{name}", value.to_s)
        end
      end
    end
  end
end