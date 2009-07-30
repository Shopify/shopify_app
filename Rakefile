require 'rubygems'

require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'ftools'

VERSION = '0.0.1'

puts 'Starting to build a new Gem...'
spec = Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.name = "shopify_app_generator"
    s.version = VERSION
    s.author = "Jaded Pixel"
    s.email = "dennis@gmail.com"
    s.homepage = "http://github.com/Shopify/api"
    s.summary = "This Gem is used to get quickly started with the Shopify API."
    s.rubyforge_project = "shopify-api"
    s.description = "Creates a basic login controller for authenticating with your Shop and also a product controller which lets your edit your products easily."
    s.files = FileList['*.rb', 'lib/*.rb', 'templates/*', 'templates/stylesheets/*', 'templates/layouts/*', 'templates/dashboard/*', 'templates/dashboard/views/*', 'templates/login/*', 'templates/login/views/*'].to_a
    # s.executables = ['shopify']
    # s.test_files = Dir.glob('tests/*.rb')
    s.has_rdoc = false
    # s.extra_rdoc_files = ["README"]
    s.add_dependency 'activesupport'
    s.add_dependency 'activeresource'
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = false
end

task :default => "pkg/#{spec.name}-#{spec.version}.gem" do
    puts "Generated latest version of Shopify API Gem: #{VERSION}"
end

desc "Publish the API documentation"
task :update_api => "../shopify/app/services/shopify_api.rb" do
  puts "Updating shopify_api.rb with newest..."
  # TODO do this as a failover to pulling down straight from git
  File.copy('../shopify/app/services/shopify_api.rb', 'lib/shopify_api.rb')
  print "Done\n"
end
