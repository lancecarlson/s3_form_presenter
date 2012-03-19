require 'rubygems'
require 'rubygems/package_task'
require 'bundler/setup'

def gemspec
  $s3_form_presenter_gemspec ||= Gem::Specification.load("s3_form_presenter.gemspec")
end

task :gem => :gemspec

desc %{Validate the gemspec file.}
task :gemspec do
  gemspec.validate
end

desc %{Release the gem to RubyGems.org}
task :release => :gem do
  sh "gem push pkg/#{gemspec.name}-#{gemspec.version}.gem"
end

task :build => :gemspec do
  sh "mkdir -p pkg"
  sh "gem build s3_form_presenter.gemspec"
  sh "mv s3_form_presenter-#{S3_Form_Presenter::VERSION}.gem pkg"
end
