require 'yaml'
require 'erb'

module WPRake

  # Factory to acquire an instance of WPRake::WPRake.
  #
  # Expects a hash with these keys:
  #
  # configfile - absolute path to a yaml config file
  # basedir    - directory rake was called in (most of the time that's Dir.pwd)
  #
  def self.init(arguments)

    yaml    = YAML.load_file(arguments[:configfile])
    config  = yaml['config'].each_with_object({}) {|(k,v), o| o[k.to_sym] = v}
    basedir = arguments[:basedir]

    setup   = WPRake::Setup.new(config, basedir)

    # Evaluate Ruby code in config
    setup.mycnf    = ERB.new(yaml['mycnf']).result(setup.get_binding)
    setup.inject   = ERB.new(yaml['wp_config_inject']).result(setup.get_binding)
    setup.htaccess = ERB.new(yaml['htaccess']).result(setup.get_binding)

    WPRake.new(setup)
  end

  # Provides config data and acts as a front to WPConfig (cf. below).
  #
  class WPRake

    # Processes config data.
    #
    class Setup

      attr_accessor :config, :htaccess, :mycnf, :inject

      def get_binding
        binding
      end

      def initialize(config, basedir)
        @config = config.merge(basedir: basedir)

        [:basedir, :wp, :wp_content, :tmp].each do |key|
          @config[key] = File.expand_path(@config[key])
        end
      end
    end

    attr_accessor :setup, :config

    def update_wp_config(file)
      WPConfig::parse!(file, @config, @setup.inject)
    end

    def initialize(setup)
      @setup  = setup
      @config = setup.config
    end
  end

  # Processes wp-config.php, i.e. applies config & injects config snippet.
  #
  module WPConfig

    def self.parse!(file, config, inject)

      uri   = URI('https://api.wordpress.org/secret-key/1.1/salt/') # Secrets & Salts
      salts = Net::HTTP.get(uri).split(/(?<=;\n)/) # Positive lookbehind to keep splitting delimiters

      content = File.readlines(file)

      content.map! do |line|

        if data = /'(DB_[A-Z]+)'[^']+'(.+)'/.match(line)
          key = data[1].downcase.to_sym
          line.sub!(data[2], config[key]) if config[key]
        end

        if data = /'([A-Z]+[_A-Z]+_(?:KEY|SALT))'/.match(line)
          line = salts.find { |salt| salt.include?(data[1]) } || line
        end

        if line =~ /^[$]table_prefix/
          line.sub!('wp_', config[:table_prefix]) if config[:table_prefix]
        end

        if line =~ /'WP_DEBUG'/
          line.sub!('false', 'true') if config[:wp_debug]
          line << inject if inject
        end

        line
      end

      File.write(file, content.join)
    end
  end
end
