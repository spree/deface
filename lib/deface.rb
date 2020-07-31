require "action_view"
require "action_controller"
require "deface/errors"
require "deface/template_helper"
require "deface/original_validator"
require "deface/applicator"
require "deface/search"
require "deface/digest"
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

require "deface/railtie" if defined?(Rails)

module Deface
  @before_rails_6 = ActionView.gem_version < Gem::Version.new('6.0.0')
  @template_class = @before_rails_6 ? ActionView::CompiledTemplates : ActionDispatch::DebugView

  def self.before_rails_6?
    @before_rails_6
  end

  def self.template_class
    @template_class
  end

  if defined?(ActiveSupport::Digest)
    Deface::Digest.digest_class = ActiveSupport::Digest
  end
end
