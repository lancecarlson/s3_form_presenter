$:.push File.expand_path('../lib', __FILE__)
require 's3_form_presenter/version'

Gem::Specification.new do |gem|
  gem.name = "s3_form_presenter"
  gem.version = S3FormPresenter::VERSION
  gem.rubyforge_project = 's3_form_presenter'
  gem.summary = %Q{Generates a simple form that is compatible with S3's form API.}
  gem.description = %Q{Generates a simple form that is compatible with S3's form API. You can upload S3 assets directly to S3 without hitting your server.}
  gem.email = ["lancecarlson@gmail.com"]
  gem.homepage = "http://github.com/lancecarlson/s3_form_presenter"
  gem.authors = ["Lance Carlson"]

  gem.files = `git ls-files`.split("\n")
  gem.test_files = `git ls-files -- {tests}/*`.split("\n")
  gem.require_paths = ['lib']
end
