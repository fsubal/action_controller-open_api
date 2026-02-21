require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :dummy do
  APP_ROOT = File.expand_path("test/dummy", __dir__)

  desc "Start the dummy app server"
  task :server do
    Dir.chdir(APP_ROOT) { sh "bin/rails server" }
  end

  desc "Open the dummy app console"
  task :console do
    Dir.chdir(APP_ROOT) { sh "bin/rails console" }
  end

  desc "Run a Rails command in the dummy app (e.g. rake dummy:rails[routes])"
  task :rails, [:command] do |_t, args|
    Dir.chdir(APP_ROOT) { sh "bin/rails #{args[:command]}" }
  end
end
