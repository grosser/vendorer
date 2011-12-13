require "bundler"
Bundler::GemHelper.install_tasks

task :default do
  sh "rspec spec/"
end

rule /^version:bump:.*/ do |t|
  file = 'lib/vendorer/version.rb'
  sh "git status | grep 'nothing to commit'" # ensure we are not dirty
  index = ['major', 'minor','patch'].index(t.name.split(':').last)
  version_file = File.read(file)
  old_version, *version_parts = version_file.match(/(\d+)\.(\d+)\.(\d+)/).to_a
  version_parts[index] = version_parts[index].to_i + 1
  new_version = version_parts * '.'
  File.open(file,'w'){|f| f.write(version_file.sub(old_version, new_version)) }

  sh "bundle && git add #{file} Gemfile.lock && git commit -m 'bump version to #{new_version}'"
end
