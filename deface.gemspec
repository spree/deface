Gem::Specification.new do |s|
  s.name = "deface"
  s.version = "0.8.0"

  s.authors = ["Brian D Quinn"]
  s.description = "Deface is a library that allows you to customize ERB & HAML views in a Rails application without editing the underlying view."
  s.email = "brian@spreecommerce.com"
  s.extra_rdoc_files = [
    "README.markdown"
  ]
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.homepage = "http://github.com/railsdog/deface"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.summary = "Deface is a library that allows you to customize ERB & HAML views in Rails"

  s.add_dependency('nokogiri', '~> 1.5.0')
  s.add_dependency('rails', '~> 3.1')

  s.add_development_dependency('rspec', '>= 2.8.0')
  s.add_development_dependency('haml', '>= 3.1.4')
end
