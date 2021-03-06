require 'rspec/core/rake_task'
require 'rubygems/package_task'
require './lib/txdb'

Bundler::GemHelper.install_tasks

desc 'Run specs'
RSpec::Core::RakeTask.new do |t|
  t.pattern = './spec/**/*_spec.rb'
end

task default: :spec

namespace :spec do
  desc 'Run full spec suite'
  task full: [:full_spec_env, :spec]

  task :full_spec_env do
    ENV['FULL_SPEC'] = 'true'
  end
end

namespace :version do
  task :bump, [:level] do |t, args|
    levels = %w(major minor patch)
    level = args[:level]

    until levels.include?(level)
      STDOUT.write("Indicate version bump level (#{levels.join(', ')}): ")
      level = STDIN.gets.strip

      unless levels.include?(level)
        puts "That's not a valid version bump level, try again."
      end
    end

    level.strip!

    major, minor, patch = Txdb::VERSION.split('.').map(&:to_i)

    case level
      when 'major'
        major += 1; minor = 0; patch = 0
      when 'minor'
        minor += 1; patch = 0
      when 'patch'
        patch += 1
    end

    new_version = [major, minor, patch].join('.')
    puts "Bumping from #{Txdb::VERSION} to #{new_version}"

    # rewrite version.rb
    version_file = './lib/txdb/version.rb'
    contents = File.read(version_file)
    contents.sub!(/VERSION\s*=\s['"][\d.]+['"]$/, "VERSION = '#{new_version}'")
    File.write(version_file, contents)

    # update constant in case other rake tasks run in this process afterwards
    Txdb::VERSION.replace(new_version)
  end

  task :history do
    history = File.read('History.txt')
    history = "== #{Txdb::VERSION}\n* \n\n#{history}"
    File.write('History.txt', history)
    system "vi History.txt"
  end

  task :commit_and_push do
    system "git add lib/txdb/version.rb"
    system "git add History.txt"
    system "git commit -m 'Bumping version to #{Txdb::VERSION}'"
    system "git push origin HEAD"
  end
end

DOCKER_REPO = 'quay.io/lumoslabs/txdb'

namespace :publish do
  task :all do
    task_names = %w(
      version:bump version:history version:commit_and_push
      publish:tag publish:update_docker_base_image publish:build_docker
      publish:publish_docker publish:build_gem publish:publish_gem
    )

    task_names.each do |task_name|
      STDOUT.write "About to execute #{task_name}, continue? (yes/no/skip): "
      answer = STDIN.gets

      case answer.downcase
        when /ye?s?/
          Rake::Task[task_name].invoke
        when /no?/
          puts "Exiting!"
          exit 0
        else
          puts "Skipping #{task_name}"
      end
    end
  end

  task :tag do
    system("git tag -a v#{Txdb::VERSION} && git push origin --tags")
  end

  task :update_docker_base_image do
    system("docker pull ruby:2.3")
  end

  task :build_docker do
    system("docker build -t #{DOCKER_REPO}:latest -t #{DOCKER_REPO}:v#{Txdb::VERSION} .")
  end

  task :publish_docker do
    system("docker push #{DOCKER_REPO}:latest")
    system("docker push #{DOCKER_REPO}:v#{Txdb::VERSION}")
  end

  task :build_gem => [:build]  # use preexisting build task from rubygems/package_task

  task :publish_gem do
    system("gem push pkg/txdb-#{Txdb::VERSION}.gem")
  end
end

task publish: 'publish:all'
