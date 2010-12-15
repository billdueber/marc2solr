require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "any2solr"
    gem.summary = %Q{any2solr: Get data into Solr via JRuby}
    gem.description = %Q{A basic framework for dealing with sending data to solr based on user-supplied readers/translators}
    gem.email = "bill@dueber.com"
    gem.homepage = "http://github.com/billdueber/marc2solr"
    gem.authors = ["BillDueber"]
    
    gem.add_dependency 'jruby_streaming_update_solr_server', '>=0.5.2'
    gem.add_dependency 'threach', '>= 0.2.0'
    gem.add_dependency 'jlogger', '>=0.0.4'
    gem.add_dependency 'trollop'
    
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "yard", ">= 0"

    gem.bindir = 'bin'
    
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
