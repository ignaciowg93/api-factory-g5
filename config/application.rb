require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ApiFactoryG5
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    config.middleware.use ActionDispatch::Flash
    config.middleware.use Rack::MethodOverride
    config.middleware.use ActionDispatch::Cookies

    config.secret = "%hG4INNjIAYx9&0"#'W1gCjv8gpoE4JnR'
    config.base_route_oc = "https://integracion-2017-prod.herokuapp.com/oc/"
    config.base_route_bodega = "https://integracion-2017-prod.herokuapp.com/bodega/"
    config.base_route_banco = "https://integracion-2017-prod.herokuapp.com/banco/"
    config.recepcion_id = "5910c0b90e42840004f6e9ec" #"590baa76d6b4ec00049028b1"
    config.despacho_id = "590baa76d6b4ec00049028b2"
    config.pulmon_id = "5910c0ba0e42840004f6ea7c" #"590baa76d6b4ec00049029dc"
    config.intermedio_id_1 = "5910c0b90e42840004f6e9ee" #prod
    config.intermedio_id_2 = "5910c0ba0e42840004f6ea7b" #prod
    config.my_id = "5910c0910e42840004f6e684" #prod
    config.time_zone = 'Santiago'
  end
end
