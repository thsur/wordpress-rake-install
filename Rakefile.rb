#
# Example of how to include WPRake into an existing Rakefile.
#
# All tasks will get executed in the directory the Rakefile's in.
# This is also where WordPress gets installed when calling
# rake with wprake:install_everything.
#

require 'rake'

# Load wp-rake
load 'tasks/wprake/wprake.rake'

# Show its tasks
task :default do
  sh 'rake --tasks wprake'
end

# Roll your own
task :install_with_theme do

  Rake::Task['wprake:install_everything'].invoke

  puts "Fetching us a theme..."

  Dir.chdir('content/themes') do
    sh 'wget -nv https://github.com/Automattic/_s/archive/master.zip && unzip -q master.zip && rm master.zip'
    sh "mv _s-master _s"
  end

  puts 'Switching theme...'

  Rake::Task['wprake:call_endpoint'].invoke('wp-actions.php', 'theme=_s')
end


