#
# Example of how to include WPRake into an existing Rakefile.
#
# All tasks will get executed in the directory the Rakefile's in.
# This is also where WordPress gets installed when calling
# rake with e.g. wprake:install_everything.
#

require 'rake'

# Load wp-rake
load 'tasks/wprake/wp-rake.rake'

# Use its tasks
task :default do
  sh 'rake --tasks wprake'
end
