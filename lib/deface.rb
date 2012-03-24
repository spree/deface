require "action_view"
require "action_controller"
require "deface/template_helper"
require "deface/original_validator"
require "deface/applicator"
require "deface/search"
require "deface/override"
require "deface/parser"
require "deface/environment"
require "deface/dsl/loader"

module Deface
  if defined?(Rails)
    require "deface/railtie"
  end
end
