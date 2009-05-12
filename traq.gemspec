# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name = %q{traquitana}
  s.version = "0.0.1"
 
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Eustaquio Rangel"]
  s.date = %q{2009-05-12}
  s.description = %q{Simple tool for deploy Rails apps}
  s.email = %q{eustaquiorangel@gmail.com}
  s.bindir = "bin"
  s.executables = ["traq"]
  s.files = ["bin/traq", "lib/config.rb", "lib/deploy.rb", "config/default.yml", "config/passenger.sh", "config/proc.sh"]
  s.has_rdoc = false
  s.homepage = %q{http://github.com/taq/traquitana}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Simple tool for deploy Rails apps}
 
	s.add_dependency("rubyzip", [">= 0"])
	s.add_dependency("net-ssh", [">= 0"])
	s.add_dependency("net-scp", [">= 0"])
end
