# -*- encoding : utf-8 -*-

require 'active_support'
require 'active_support/core_ext'
require 'logger'
require 'forwardable'
require 'ashikawa-core'
require 'yaml'
require 'erb'

require 'guacamole/document_model_mapper'

module Guacamole
  class << self
    # Configure Guacamole
    #
    # Takes a block in which you can configure Guacamole.
    # @return [Configuration] the resulting configuration
    def configure(&config_block)
      config_block.call configuration

      configuration
    end

    # Contains the configuration of Guacamole
    #
    # @return [Configuration]
    def configuration
      @configuration ||= Configuration
    end

    # Just an alias to Configuration#logger
    #
    # @return [Configuration#logger]
    def logger
      configuration.logger
    end
  end

  # Current configuration
  #
  # You can receive the configuration by calling Guacamole.configuration
  #
  # @!attribute self.database
  #   The raw Database object
  #
  #   The Database implementation is part of Ashikawa::Core
  #
  #   @see http://rubydoc.info/gems/ashikawa-core/Ashikawa/Core/Database
  #   @return [Ashikawa::Core::Database]
  #
  # @!attribute self.default_mapper
  #   The Mapper class that is used by default. This defaults to
  #   DocumentModelMapper
  #
  #   @return [Class] the default mapper class
  #
  # @!attribute self.logger
  #   The logger
  #
  #   This defaults to the Rails logger
  #
  #   @return [Object] the logger
  #
  # @!attribute [r] self.current_environment
  #   The current environment Guacamole is running in
  #
  #   If you are running in Rails, this will return the current Rails environment
  #
  #   @return [Object] current environment
  class Configuration
    # A wrapper object to handle both configuration from a connection URI and a hash.
    class ConfigStruct
      attr_reader :url, :username, :password

      def initialize(config_hash_or_url)
        case config_hash_or_url
        when Hash
          init_from_hash(config_hash_or_url)
        when String
          init_from_uri_string(config_hash_or_url)
        end
      end

      private

      def init_from_uri_string(uri_string)
        uri       = URI.parse(uri_string)
        @username = uri.user
        @password = uri.password
        uri.user  = nil

        @url = uri.to_s
      end

      def init_from_hash(hash)
        @username = hash['username']
        @password = hash['password']
        @url      = "#{hash['protocol']}://#{hash['host']}:#{hash['port']}/_db/#{hash['database']}"
      end
    end

    # @!visibility protected
    attr_accessor :database, :default_mapper, :logger

    AVAILABLE_EXPERIMENTAL_FEATURES = [
      :aql_support
    ]

    class << self
      extend Forwardable

      def_delegators :configuration,
                     :database, :database=,
                     :default_mapper=,
                     :logger=,
                     :experimental_features=, :experimental_features

      def default_mapper
        configuration.default_mapper || (self.default_mapper = Guacamole::DocumentModelMapper)
      end

      def logger
        configuration.logger ||= (rails_logger || default_logger)
      end

      # Load a YAML configuration file to configure Guacamole
      #
      # @param [String] file_name The file name of the configuration
      def load(file_name)
        yaml_content  = process_file_with_erb(file_name)
        config        = YAML.load(yaml_content)[current_environment.to_s]
        config_struct = build_config(config)

        self.database = create_database_connection(config_struct)
      end

      # Creates a config struct from either a hash or a DATABASE_URL
      #
      # @param [Hash, String] config Either a hash containing config params or a complete connection URI
      # @return [ConfigStruct] A simple object with the required connection parameters
      # @api private
      def build_config(config)
        ConfigStruct.new config
      end

      # Creates the actual Ashikawa::Core::Database instance
      #
      # @param [ConfigStruct] config The config object to extract the config parameters from
      # @return [Ashikawa::Core::Database] The configured database instance
      # @api private
      def create_database_connection(config)
        Ashikawa::Core::Database.new do |arango_config|
          arango_config.url      = config.url
          arango_config.username = config.username
          arango_config.password = config.password
          arango_config.logger   = logger
        end
      end

      def current_environment
        return Rails.env if defined?(Rails)
        ENV['RACK_ENV'] || ENV['GUACAMOLE_ENV']
      end

      private

      def configuration
        @configuration ||= new
      end

      def rails_logger
        return Rails.logger if defined?(Rails)
      end

      def default_logger
        default_logger       = Logger.new(STDOUT)
        default_logger.level = Logger::INFO
        default_logger
      end

      def process_file_with_erb(file_name)
        ERB.new(File.read(file_name)).result
      end
    end

    # A list of active experimental features. Refer to `AVAILABLE_EXPERIMENTAL_FEATURES` to see
    # what can be activated.
    #
    # @return [Array<Symbol>] The activated experimental features. Defaults to `[]`
    def experimental_features
      @experimental_features || []
    end

    # Experimental features to activate
    #
    # @param [Array<Symbol>] features A list of experimental features to activate
    def experimental_features=(features)
      @experimental_features = features
    end
  end
end
