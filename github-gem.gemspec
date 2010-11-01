# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "github/version"

Gem::Specification.new do |s|
  s.name        = "github"
  s.version     = GitHub::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Chris Wanstrath', 'Kevin Ballard', 'Scott Chacon', 'Dr Nic Williams']
  s.email       = ["drnicwilliams@gmail.com"]
  s.homepage    = "http://github/defunkt/github-gem"
  s.summary     = "The official `github` command line helper for simplifying your GitHub experience."
  s.description = "The official `github` command line helper for simplifying your GitHub experience."

  s.rubyforge_project = "github"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency "text-format", "1.0.0"
  s.add_dependency "highline", "~> 1.5.1"
  s.add_dependency "json", "~> 1.4.6"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "1.3.1"
end
