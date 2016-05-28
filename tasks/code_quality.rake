require 'json'
require 'rubocop/rake_task'
$LOAD_PATH.unshift(__dir__)
require 'support/console'
require 'reek/rake/task'

Reek::Rake::Task.new do |t|
  t.fail_on_error = false
  t.source_files  = FileList.new('lib/**/*.rb', 'spec/**/*.rb')
end

RuboCop::RakeTask.new

task :coverage_check do
  required_percentage = 100
  percentage = JSON(File.read("#{__dir__}/../coverage/.last_run.json"))['result']['covered_percent']
  unless percentage == required_percentage
    Console.error "Expected coverage: #{required_percentage}% got: #{percentage}%"
    exit 1
  end
end
