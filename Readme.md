
# WPRake. Quick Install WordPress With Rake And A Bash

Install WordPress in less than a minute. Wipe your install in seconds.  

## Audience

If you have a Bash and a Ruby installation running (try `ruby -v`), this is for you. See [Requirements](#requirements) for details.  

This also is for:

* Theme and plugin developers who need to set up a fresh install on a regular basis, and want to be able to tear it down again without fuss.
* Maintainers and developers who want to roll their own batch or quick installation process, and are looking for something to hack and extend.
* People looking for something plain, fast and lightweight. 

That said, you also might want to check out these [fine](http://wp-cli.org/) [alternative](https://github.com/GeekPress/WP-Quick-Install) [solutions](https://github.com/wesleytodd/YeoPress), including the [more involved](https://github.com/Varying-Vagrant-Vagrants/VVV) ones. 

## Quick Start

### Get It

Switch to the shell and make sure you have Rake installed (try `rake --version`). If not, get and install it with:

`$ gem install rake`

Create a folder to hold your WordPress project, `cd` into it, then download WPRake and unpack it. Both the sample Rakefile and the 'tasks' folder should be on your project's root afterwards.

### Configure It

First, rename the default configuration file:

`$ mv tasks/wprake/config.sample.yml tasks/wprake/config.yml`

Then fire up an editor and update its settings:

* adjust all `db_` settings under 'Database'
* set a valid URL to `local` under 'URLs'

### Call It

Install WordPress with:

`$ rake wprake:install_everything` 

Wait until the script says 'done'. Read the rest of its message to successfully log in to your WordPress installation. 

## What It Is

A bunch of scripts meant to be hacked by you. Though by default, you will only need to adjust one single configuration file to be ready to go. 

It ships with a a sample configuration, and a sample Rakefile demonstrating how to include WPRake into your own Rake-based build process.  

## What It Does

When installing, it will 

* create a database
* create a directory structure to separate the system from your content (called 'wordpress' and 'content' by default, the latter being WordPress renowned 'wp-content' folder) 
* download, configure and install the latest WordPress version
* download, install and activate any plugins mentioned in the config file (by default, this would be 'debug-bar', 'user-switching', 'wp-no-category-base')
* create a .htaccess file   
* create an admin and an editor user
* create a hidden file called .users holding the credentials of both users 
* call a post install routine to further configure WordPress (see [Advanced Usage](#advanced_usage) for details)

When wiping, it will

* remove all files and folders related to WordPress _including everything_ inside your content folder
* drop the database  
* ask for confirmation first

When you also have mysqldump sitting on the Bash, it will be able to

* export the database 
* replace all occurrences of the installation's local URL with its remote one for easily importing the dump into your remote db

## What It Does Not

A lot. Because it has opinions, but only a few by default (unless you tweak it, that is). For example, it doesn't install a theme. But it gives an example of how to download one and switch to it. See the [sample Rakefile] for details.

## <a id="requirements"></a>Requirements

* PHP >= 5.3 (though any PHP 5.x should work, too)
* Ruby >= 2.0 (though 1.9.x might work, too)
* Rake 
* a Bash 

Regarding the Bash, the following tools need to be available:

* wget
* curl
* unzip
* mysql
* mysqldump (optional)

## Installation

If you haven't installed [Rake](https://github.com/ruby/rake) (try `rake --version`), the famous Ruby build tool, switch to the shell, and call Ruby's packet manager with:

`$ gem install rake`

Create some folder to hold your project, `cd` into it, then download WPRake and unpack it. Both the sample Rakefile and the 'tasks' folder should be on  your project's root afterwards.

Simply do:

`$ rake`   

to see a list of available commands. You should see (not in the given order, though):

* `rake wprake:install_everything`
* `rake wprake:wipe_everything`
* `rake wprake:export_db`
* `rake wprake:update_wordpress`

Before you try them, make sure to provide a minimal configuration (see next section).

## Configuration

To configure WPRake, you will first need to rename its default configuration file. From within the shell, do

`$ mv tasks/wprake/config.sample.yml tasks/wprake/config.yml`

to rename it, then fire up an editor and update its settings. It's well documented, and if you ever have installed WordPress before, most of it should look familiar. 

For a minimal setup, 

* adjust all `db_` settings under 'Database'
* set a valid URL to `local` under 'URLs'

By the way, the configuration's notation is YAML. If you are unaccustomed to it, see:

* [The YAML Format](http://symfony.com/doc/current/components/yaml/yaml_format.html)
* [YAML Online Parser](http://yaml-online-parser.appspot.com/)   

## Usage

From your project's root, do

`rake wprake:install_everything`

to give it a try.

When all is done, you will see a message saying so. Carefully read what else it has to say to successfully log in to your freshly created WordPress installation.

## <a id="advanced_usage"></a>Advanced Usage

WPRake centers around three main files:

* the config file you already know about
* a central task file (`tasks/wprake/wprake.rake`) 
* a post install endpoint (`tasks/wprake/wp-post-install.php`)

### Post Install

When WPRake has finished the main installation process, it issues a HTTP request to a PHP post install endpoint. It's [that file] you probably want to adjust next to the configuration file. 

Just have a look at it. It's pretty basic and self-explanatory, so you should find your way around easily.  

When done, tear your install down with `rake wprake:wipe_everything` and install it again to see _your_ post install settings applied.

By the way, there is another endpoint called 'wp-actions.php', meant for hooks to be called after WordPress has been fully installed. Again, have a look at the sample Rakefile to get an idea of how to use it.

Both files load WordPress as their environment, so you should have everything you need at your hands. In case something is missing, just extend what gets loaded.  

### About Rake

You should come far by only adjusting the configuration, and what's happening inside 'wp-post-install.php', but finally, you might want to add a new task. Something that syncs your remote with your local installation, for example. 

But you don't know a single thing about Rake. Or Ruby. But don't fret. Instead, imagine Rake to be a tool for building up a shell script. Look at this:

```Ruby
task :list_directory do
    # Call the shell
    sh "ls -la ."
end
```    

Add this to the sample Rakefile and call it with:

`$ rake list_directory`

It's that simple, really. Browse Rake's [Readme](https://github.com/ruby/rake) and Martin Fowler's [article about Rake](http://martinfowler.com/articles/rake.html) for much more info. Or just go ahead and do some Bash magic with it. 

### Modifying wprake.rake

Despite configuration and post installation, you finally might want to tweak the installation process itself. The place to look for is ['/tasks/wprake/wprake.rake']. It's the core of WPRake, so to speak, and it's fair to say that it might be in need of a cleanup. Never mind, though, and happily hack away. 

# License

X11 ('MIT') License 
