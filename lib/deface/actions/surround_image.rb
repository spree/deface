module Deface
  module Actions
    class SurroundImage < SurroundAction
      def execute(target_range)
        original_placeholders.each do |placeholder|
          start = target_range[0].clone(1)
          placeholder.replace start

          target_range[1..-1].each do |element|
            element = element.clone(1)
            start.after element
            start = element
          end
        end
        img_element = source_element.search('img').first
        erb_variable = Nokogiri::XML::Node.new("erb", source_element)
        erb_variable['silent'] = ''
        erb_variable.content = "image_name = '#{img_element.attribute('id')}'"
        source_element.children.first.add_previous_sibling(erb_variable)

        target_range.first.before(source_element)
        target_range.map(&:remove)
      end

      def range_compatible?
        true
      end
    end
  end
end
