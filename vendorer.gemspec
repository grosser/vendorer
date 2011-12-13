$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
name = "vendorer"
require "#{name}/version"

Gem::Specification.new name, Vendorer::VERSION do |s|
  s.summary = "Keep your vendor files up to date"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/#{name}"
  s.files = `git ls-files`.split("\n")
  s.license = 'MIT'
end
