require "action_view"
require "action_controller"
require "deface/template_helper"
require "deface/original_validator"
require "deface/applicator"
require "deface/search"
require "deface/override"
require "deface/parser"
require "deface/dsl/loader"
require "deface/sources/source"
require "deface/sources/text"
require "deface/sources/erb"
require "deface/sources/haml"
require "deface/sources/slim"
require "deface/sources/partial"
require "deface/sources/template"
require "deface/sources/copy"
require "deface/sources/cut"
require "deface/actions/action"
require "deface/actions/element_action"
require "deface/actions/replace"
require "deface/actions/remove"
require "deface/actions/replace_contents"
require "deface/actions/surround_action"
require "deface/actions/surround"
require "deface/actions/surround_contents"
require "deface/actions/insert_before"
require "deface/actions/insert_after"
require "deface/actions/insert_top"
require "deface/actions/insert_bottom"
require "deface/actions/attribute_action"
require "deface/actions/set_attributes"
require "deface/actions/add_to_attributes"
require "deface/actions/remove_from_attributes"
require "deface/matchers/element"
require "deface/matchers/range"
require "deface/environment"
require "deface/precompiler"
require "colorize"

module Deface
  if defined?(Rails)
    require "deface/railtie"
  end

  # Exceptions
  class DefaceError < StandardError; end

  class NotSupportedError < DefaceError; end

end
