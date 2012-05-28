module Deface
  module Actions
    class RemoveFromAttributes < AttributeAction
      def execute_for_attribute(target_element, name, value)
        if target_element.attributes.key?(name)
          target_element.set_attribute(name, target_element.attributes[name].value.gsub(value.to_s, '').strip)
        elsif target_element.attributes.key?("data-erb-#{name}")
          target_element.set_attribute("data-erb-#{name}", target_element.attributes["data-erb-#{name}"].value.gsub(value.to_s, '').strip)
        end
      end
    end
  end
end