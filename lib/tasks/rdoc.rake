# lib/tasks/rdoc.rake
require 'rdoc/task'

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'CalInvite Documentation'
  rdoc.main     = 'README.md'
  rdoc.options << '--line-numbers'
  rdoc.options << '--charset' << 'UTF-8'
  rdoc.options << '--markup' << 'markdown'
  rdoc.rdoc_files.include('README.md', 'LICENSE', 'lib/**/*.rb')
  rdoc.rdoc_files.exclude('lib/cal_invite/version.rb')
end
