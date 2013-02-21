require 'deface'

namespace :deface do

  desc "Precompiles overrides into template files"
  task :precompile => [:environment, :clean] do |t, args|
    Deface::Precompiler.precompile()
  end

  desc "Removes all precompiled override templates"
  task :clean do
    FileUtils.rm_rf Rails.root.join("app/compiled_views")
  end

end
