require 'deface'

namespace :deface do

  desc "Precompiles overrides into template files"
  task :precompile => [:environment, :clean] do |t, args|
    require "deface/action_view_extensions"
    Deface::Precompiler.precompile()
  end

  desc "Removes all precompiled override templates"
  task :clean do
    FileUtils.rm_rf Rails.root.join("app/compiled_views")
  end

end
