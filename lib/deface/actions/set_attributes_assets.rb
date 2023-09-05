module Deface
  module Actions
    class SetAttributesAssets < AttributeAction
      def execute_for_attribute(target_element, name, value)
        current_value = target_element.attributes[name]&.value
        target_element.remove_attribute(name)
        target_element.remove_attribute("data-erb-#{name}")
        if current_value
          target_element.set_attribute("data-erb-#{name}", ActionController::Base.helpers.asset_path(current_value.to_s))
        else
          # target_element.set_attribute("data-erb-#{name}", value.to_s)
          target_element
        end
      end
    end
  end
end
