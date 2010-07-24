require 'rubygems'
require 'rake'
require 'rcov'
require 'spec/rake/spectask'
require 'metric_fu'

task :default => 'rcov'

desc "Run all specs and rcov in a non-sucky way"
Spec::Rake::SpecTask.new(:rcov) do |t|
  t.spec_opts = IO.readlines("spec/spec.opts").map {|l| l.chomp.split " "}.flatten
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_opts = IO.readlines("spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
end

MetricFu::Configuration.run do |config|
  #define which metrics you want to use
  config.metrics  = [:churn, :saikuro, :flog, :flay, :reek, :roodi]
  config.graphs   = [:flog, :flay, :reek, :roodi]
  config.flay     = { :dirs_to_flay =>  ['lib'], :minimum_score => 100  } 
  config.flog     = { :dirs_to_flog =>  ['lib']}
  config.reek     = { :dirs_to_reek =>  ['lib']}
  config.roodi    = { :dirs_to_roodi => ['lib']}
  config.saikuro  = { :output_directory => 'scratch_directory/saikuro', 
    :input_directory => ['lib'],
    :cyclo => "",
    :filter_cyclo => "0",
    :warn_cyclo => "5",
    :error_cyclo => "7",
    :formater => "text"} #this needs to be set to "text"
  config.churn    = { :start_date => "1 year ago", :minimum_churn_count => 10}
  config.graph_engine = :bluff
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "ruhl"
    gemspec.summary = "Ruby Hypertext Language"
    gemspec.description = "Make your HTML dynamic with the addition of a data-ruhl attribute."
    gemspec.email = "andy@stonean.com"
    gemspec.homepage = "http://github.com/stonean/ruhl"
    gemspec.authors = ["Andrew Stone"]
    gemspec.add_dependency('nokogiri','=1.4.2')
    gemspec.add_development_dependency('rspec')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

