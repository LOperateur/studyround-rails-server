require_relative 'boot'
# require_relative 'initializers/secret_manager'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ULearnserver
  class Application < Rails::Application
    # Use as API-only app
    config.api_only = true

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.active_job.queue_adapter = :sidekiq

    # Tip from https://github.com/mperham/sidekiq/wiki/Active+Job#queues
    # Disable the standard Rails queues
    # Using nil will use the "default" queue instead of the rails defaults
    # Fixed in Rails 6.1
    config.action_mailer.deliver_later_queue_name = :mailers

    # Prevent some default files from being auto-generated
    config.generators.template_engine = false
    config.generators.assets = false
    config.generators.helper = false

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Default is UTC. To see all, run rake time:zones:all
    config.time_zone = 'UTC'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    if Rails.env.production?
      # TODO: Set rails config with required origin
    else
      config.middleware.insert_before 0, Rack::Cors do
        allow do
          origins '*'
          resource '*', :headers => :any, :methods => [:get, :post, :put, :patch, :delete, :options, :head]
        end
      end
    end

    config.autoload_paths += [Rails.root.join('app', 'models', 'validators').to_s]
  end
end
