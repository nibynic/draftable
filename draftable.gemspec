$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "draftable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "Draftable"
  spec.version     = Draftable::VERSION
  spec.authors     = ["Paweł Bator"]
  spec.email       = ["jembezmamy@users.noreply.github.com"]
  spec.homepage    = "http://github.com/nibynic/draftable"
  spec.summary     = "Drafts for Rails Active Record"
  spec.description = "Drafts for Rails Active Record that use your models and validations"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = ""
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 5.2.2"

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "spy"
end
