require 'deface'
require 'deface/utils/failure_finder'
require 'rainbow'

namespace :deface do
  include Deface::TemplateHelper
  include Deface::Utils::FailureFinder

  desc 'Applies selectors to given partial/template, and returns match(s) source.'
  task :test_selector, [:virtual_path, :selector] => [:environment] do |t, args|

    begin
      source = load_template_source(args[:virtual_path], false)
      output = element_source(source, args[:selector])
    rescue
      puts "Failed to find template/partial"

      output = []
    end

    if output.empty?
      puts "0 matches found"
    else
      puts "Querying '#{args[:virtual_path]}' for '#{args[:selector]}'"
      output.each_with_index do |content, i|
        puts "---------------- Match #{i+1} ----------------"
        puts content
      end
    end

  end


  desc 'Get the resulting markup for a partial/template'
  task :get_result, [:virtual_path] => [:environment] do |t,args|
    puts "---------------- Before ----------------"
    before = load_template_source(args[:virtual_path], false, false).dup
    puts before
    puts ""

    overrides = Deface::Override.find(:virtual_path => args[:virtual_path])
    puts "---------------- Overrides (#{overrides.size})--------"
    overrides.each do |override|
      puts "- '#{override.name}' will#{ ' NOT' if override.args[:disabled]} be applied."
    end
    puts ""

    puts "---------------- After ----------------"
    after = load_template_source(args[:virtual_path], false, true).dup
    puts after

    begin
      puts ""
      puts "---------------- Diff -----------------"
      puts Diffy::Diff.new(before, after).to_s(:color)
    rescue
      puts "Add 'diffy' to your Gemfile to see the diff."
    end

  end

  desc 'Load and apply all overrides, and output results'
  task :test_all => [:environment] do |t|
    fail_count = Deface::Override.all.keys.map(&:to_s).inject(0) do |failed, virtual_path|
      result = output_results_by_virtual_path(virtual_path)

      failed += result
    end

    if fail_count == 0
      puts Rainbow("\nEverything's looking good!").green
      exit(0)
    else
      puts Rainbow("\nYou had a total of #{fail_count} failures.").red
      exit(1)
    end
  end

  desc 'Report on failing overrides for a partial/template'
  task :failures_by_virtual_path, [:virtual_path] => [:environment] do |t,args|
    output_results_by_virtual_path(args[:virtual_path])
  end
end
