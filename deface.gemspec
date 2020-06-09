Gem::Specification.new do |s|
  s.name = "deface"
  s.version = "1.5.3"

  s.authors = ["Brian D Quinn"]
  s.description = "Deface is a library that allows you to customize ERB, Haml and Slim views in a Rails application without editing the underlying view."
  s.email = "brian@spreecommerce.com"
  s.extra_rdoc_files = [
    "README.markdown", "CHANGELOG.markdown"
  ]
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.homepage = "https://github.com/spree/deface"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.summary = "Deface is a library that allows you to customize ERB, Haml and Slim views in Rails"

  s.required_ruby_version = Gem::Requirement.new('~> 2.3')

  s.add_dependency('nokogiri', '>= 1.6')
  s.add_dependency('rails', '>= 4.1')
  s.add_dependency('rainbow', '>= 2.1.0')
  s.add_dependency('polyglot')

  s.add_development_dependency('appraisal')
  s.add_development_dependency('erubis')
  s.add_development_dependency('rspec', '>= 3.1.0')
  s.add_development_dependency('haml', ['>= 4.0', '< 6'])
  s.add_development_dependency('slim', '~> 3.0')
  s.add_development_dependency('simplecov', '>= 0.6.4')
  s.add_development_dependency('generator_spec', '~> 0.8')
end
