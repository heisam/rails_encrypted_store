# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails_encrypted_store/version'

Gem::Specification.new do |gem|
  gem.name          = "rails_encrypted_store"
  gem.version       = RailsEncryptedStore::VERSION
  gem.authors       = ["Heiner Sameisky"]
  gem.email         = ["hei.sam@gmail.com"]
  gem.description   = "Encrypted ActiveRecord::Store"
  gem.summary       = "Encrypted ActiveRecord::Store"
  gem.homepage      = "https://github.com/heisam/rails_encrypted_store"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "gibberish"

  gem.add_development_dependency "bundler", "~> 1.3"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "sqlite3-ruby"
  gem.add_dependency "activerecord", ">= 3.2"

end