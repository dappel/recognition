$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "recognition/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "recognition"
  s.version     = Recognition::VERSION
  s.authors     = ["Omar Abdel-Wahab"]
  s.email       = ["owahab@gmail.com"]
  s.homepage    = "http://github.com/rayasocialmedia/recognition"
  s.summary     = "Recognize users by giving them points and rewards for their actions"
  s.description = "Recognize users by giving them points and rewards for their actions"
  
  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE.txt", "Rakefile", "README.md"]
  # s.files = `git ls-files`.split("\n")
  
  s.add_dependency "rails", "~> 3.2.9"
  s.add_dependency "redis"
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "capybara"
  s.add_development_dependency "yard"
  s.add_development_dependency "redcarpet"
end
