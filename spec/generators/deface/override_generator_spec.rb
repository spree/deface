require 'spec_helper'
require 'generator_spec/test_case'

describe Deface::Generators::OverrideGenerator do
  include GeneratorSpec::TestCase
  destination Dir.tmpdir

  before(:all) do
    prepare_destination
  end

  context 'using erb' do
    it "should generate a deface override with the correct path" do
      run_generator %w(posts/_post add_headline)
      assert_file 'app/overrides/posts/_post/add_headline.html.erb.deface', "<!-- insert_after 'h1' -->\n<h2>These robots are awesome.</h2>\n"
    end
  end

  context 'using haml' do
    it "should generate a deface override with the correct path" do
      run_generator %w(posts/_post add_headline -e haml)
      assert_file 'app/overrides/posts/_post/add_headline.html.haml.deface', "/\n  insert_after 'h1'\n%h2 These robots are awesome.\n"
    end
  end

  context 'using slim' do
    it "should generate a deface override with the correct path" do
      run_generator %w(posts/_post add_headline -e slim)
      assert_file 'app/overrides/posts/_post/add_headline.html.slim.deface', "/\n  insert_after 'h1'\nh2 These robots are awesome.\n"
    end
  end

end
