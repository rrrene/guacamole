# -*- encoding: utf-8 -*-

require 'guacamole'
require 'guacamole/configuration'

require 'rails'

module Guacamole
  # Class to hook into Rails configuration and initializer
  # @api private
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'guacamole/railtie/database.rake'
    end

    config.guacamole = ::Guacamole::Configuration

    # Add app/collections to autoload_paths
    initializer 'guacamole.setup_autoload_paths', before: :set_autoload_paths do |app|
      app.config.autoload_paths += %W(#{app.config.root}/app/collections)
    end

    # We're not doing migrations (yet)
    config.send(:app_generators).orm :guacamole, migration: false

    initializer 'guacamole.configure_database_connection' do
      if ENV['DATABASE_URL'].present?
        Guacamole::Configuration.configure_with_uri ENV['DATABASE_URL']
      elsif (config_file = Rails.root.join('config', 'guacamole.yml')).file?
        Guacamole::Configuration.load config_file
      else
        warn_msg = '[WARNING] No configuration could be found. Either provide a `guacamole.yml` or a connection URI with `ENV["DATABASE_URL"]`'
        warn warn_msg
        Guacamole.logger.warn warn_msg
      end
    end

    initializer 'guacamole.append-identity-map-middleware' do |app|
      app.middleware.use Guacamole::IdentityMap::Session
    end
  end
end
