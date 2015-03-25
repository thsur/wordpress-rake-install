# WPRake
#
# Rakefile to quick-install WordPress.
#
# For alternate approaches & inspiration, see:
# http://wp-cli.org/
# https://github.com/wesleytodd/YeoPress
# http://wordpress.stackexchange.com/questions/1714/initialization-script-for-standard-aspects-of-a-wordpress-website
# https://github.com/GeekPress/WP-Quick-Install
# http://www.kathyisawesome.com/421/customizing-wordpress-install/
#
# Shell commands expected to be available:
# - wget
# - curl
# - unzip
#
# These should be available from the shell, too:
# - mysql
# - mysqldump
#

require 'rake'
require 'json'
require 'securerandom'
require 'net/http'
require 'pp'

require_relative 'wp-rake'

# Helper to figure out whether or not
# we have a running WordPress db.
#
def count_tables(main)
  sql = "show tables; select found_rows();"
  res = %x(mysql --defaults-extra-file=#{main.config[:mysql_options]} --database=#{main.config[:db_name]} -e '#{sql}')
  res.match(/\d+/)[0].to_i
end

# Call a local PHP endpoint (i.e., a PHP file).
#
# +args+ gets appended as part of the query string the endpoint is called
# with, so it should be a string of the form <tt>"key=val&..."</tt>.
#
def call_endpoint(main, endpoint, args)

  base = File.dirname(__FILE__)

  system("cp #{File.join(base, endpoint)} #{main.config[:basedir]}")

  wp   = File.basename(main.config[:wp])
  url  = URI.join(main.config[:local], "#{endpoint}?wp-dir=#{wp}&#{args}")

  puts Net::HTTP.get(url)

  system("rm #{File.join(main.config[:basedir], endpoint)}")
end

#
# Init
#
#

main = WPRake::init(

  basedir: Dir.pwd,
  configfile: File.join(File.dirname(__FILE__), 'config.yml')
)

namespace :wprake do

  task init: %W(.htaccess #{main.config[:mysql_options]} #{main.config[:tmp]})

  file '.htaccess' do |task|
    File.open(task.name, 'w', 0644) {|f| f.write(main.setup.htaccess)}
  end

  file main.config[:mysql_options] do |task|
    File.open(task.name, 'w', 0600) {|f| f.write(main.setup.mycnf)}
  end

  directory main.config[:tmp] do |task|
    mkdir(main.config[:tmp], mode: 0740, verbose: false)
  end
end

Rake::Task['wprake:init'].invoke

#
# Tasks
#
#

namespace :wprake do

  task :noop

  #
  # Installation
  #
  #

  desc 'Install Wordpress with a theme & specified plugins.'
  task :install_everything => [

    :install_wordpress,
    :install_plugins,
    :post_install

    ] do

    url = URI.join(main.config[:local], File.basename(main.config[:wp]) + '/', 'wp-admin')

    puts
    puts "Done. Visit #{url} to login."
    puts "Open ./.users for login credentials."
  end

  task :create_db do

    puts 'Creating DB...'

    sql = "create database if not exists #{main.config[:db_name]} default character set utf8 default collate utf8_general_ci"
    sh "mysql --defaults-extra-file=#{main.config[:mysql_options]} -e '#{sql}'"

    if count_tables(main) != 0
      puts "There is a WordPress DB named #{main.config[:db_name]} already running. Delete it first if you want to re-install."
      exit
    end
  end

  task :update_wp_config do

    wp_config = 'wp-config.php'
    wp_sample = 'wp-config-sample.php'

    next if File.exists?(wp_config)

    Dir.chdir(main.config[:wp]) do
      sh "cp -r #{wp_sample} #{File.join(main.config[:basedir], wp_config)}"
    end

    puts 'Updating WP config file...'

    main.update_wp_config(wp_config)
  end

  task :move_wp_content do

    next if Dir.exists?(main.config[:wp_content])

    puts 'Moving wp-content...'

    mkdir(main.config[:wp_content])

    Dir.chdir(main.config[:wp]) do
      sh "cp -r wp-content/* #{main.config[:wp_content]}"
    end
  end

  task :install_wordpress => [:create_db, :update_wordpress, :update_wp_config, :move_wp_content] do

    # Generate WP users passwords & write them to a .users file
    #
    # see http://stackoverflow.com/a/7222962

    pw_admin  = SecureRandom.urlsafe_base64(12, true)
    pw_editor = SecureRandom.urlsafe_base64(12, true)

    puts 'Creating .users file containing login credentials...'

    File.write('.users', "[admin]\n#{main.config[:user]}=#{pw_admin}\n[editor]\neditor=#{pw_editor}")

    # 5-min-install

    url = URI.join(

      main.config[:local],
      File.basename(main.config[:wp])  << '/',
      'wp-admin/install.php?step=2'
    )

    puts 'Calling 5-minute-install on ' << url.to_s << '...'

    response = Net::HTTP.post_form(url, {

      'weblog_title'    => main.config[:blogtitle],
      'user_name'       => main.config[:user],
      'admin_password'  => pw_admin,
      'admin_password2' => pw_admin,
      'admin_email'     => main.config[:email],
      'blog_public'     => main.config[:blog_is_public]
    })

    if count_tables(main) == 0
      puts 'Installation failed.'
      puts 'Sorry to bother you with:'
      puts response.body
      exit
    else
      puts 'WordPress installed...'
    end

    puts 'Setting filesystem permissions...'

    sh "chmod --recursive 775 #{main.config[:wp_content]}"
  end

  task :install_plugins do

    puts 'Fetching plugins...'

    main.config[:plugins].each do |slug|

      puts "Fetching download info for #{slug}..."

      # To get some basic ideas on how to use WP's API, see:
      # http://wordpress.stackexchange.com/questions/84254/wp-org-api-accessing-plugin-downloads-today-value
      info = %x(curl --silent #{main.config[:endpoint]}#{slug}.json)
      info = JSON.parse(info)

      puts "Fetching #{slug}..."

      url  = info['download_link']
      file = File.basename(url)

      plugins = File.join(main.config[:wp_content], '/plugins')

      Dir.chdir(plugins) do
        sh "wget -nv #{url}"
        sh "unzip -q #{file} && rm #{file}"
      end
    end
  end

  task :post_install do
    puts
    puts 'Calling post install...'
    Rake::Task['wprake:call_endpoint'].invoke('wp-post-install.php', 'users=.users')
  end

  task :call_endpoint, :endpoint, :args do |t, args|
    call_endpoint(main, args[:endpoint].to_s, args[:args].to_s)
  end

  #
  # Maintenance & Convenience
  #
  #

  desc 'Update WordPress.'
  task :update_wordpress do

    puts 'Wiping current & fetching latest WP version...'

    sh "rm --recursive --force #{main.config[:wp]}"

    Dir.chdir(main.config[:tmp]) do
      sh 'wget https://wordpress.org/latest.zip && unzip -q latest.zip'
      sh "mv wordpress #{main.config[:wp]} && rm latest.zip"
    end

    Dir.chdir(main.config[:wp]) do
      sh "cp index.php #{main.config[:basedir]}"
    end

    File.write('index.php', File.read('index.php').sub(/dirname[(][^)]+[)]/, "'#{File.basename(main.config[:wp])}'"))
  end

  desc 'Export local db and replace local with remote base URL.'
  task :export_db do

    sh "mysqldump --defaults-extra-file=#{main.config[:mysql_options]} #{main.config[:db_name]} > #{main.config[:db_name]}.sql"

    file = File.expand_path(main.config[:db_name] + '.sql')

    File.open(file) do |source|

      contents = source.read
      regex    = Regexp.new(main.config[:local])

      contents.gsub!(regex, main.config[:remote])

      File.open(file, 'w+') { |f| f.write(contents) }
    end
  end

  desc 'Wipe your WordPress installation.'
  task :wipe_everything do

      puts
      puts 'WARNING'
      puts
      puts 'This will kill your WordPress install.'
      puts 'It will wipe all generated and all WordPress related files and directories.'
      puts 'Including all plugins, themes, config files.'
      puts 'And the database.'
      puts 'All of it.'
      puts
      print 'Do you really want to proceed (y/n)? '

      $stdout.flush

      # Why we use STDIN.gets instead of just gets?
      # Cf. http://stackoverflow.com/a/577851
      input = STDIN.gets.chomp!

      if input == 'y'

        puts
        puts 'Wiping...'
        puts

        sql = "drop database if exists #{main.config[:db_name]}"
        sh("mysql --defaults-extra-file=#{main.config[:mysql_options]} -e '#{sql}'")

        sh "rm --force .htaccess #{main.config[:mysql_options]} .users wp-config.php index.php"
        sh "rm --recursive --force #{main.config[:tmp]}"

        sh "rm --recursive --force #{main.config[:wp]}"
        sh "rm --recursive --force #{main.config[:wp_content]}"
      else
        puts 'Aborted.'
      end
  end
end
