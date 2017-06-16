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


    #PRODUCTION
    config.secret = "%hG4INNjIAYx9&0"
    config.base_route_oc = "https://integracion-2017-prod.herokuapp.com/oc/"
    config.base_route_bodega = "https://integracion-2017-prod.herokuapp.com/bodega/"
    config.base_route_banco = "https://integracion-2017-prod.herokuapp.com/banco/"
    config.base_route_factura = "https://integracion-2017-prod.herokuapp.com/sii/"
    config.banco_id = "5910c0910e42840004f6e68a"
    config.recepcion_id = "5910c0b90e42840004f6e9ec"
    config.despacho_id = "5910c0b90e42840004f6e9ed"
    config.pulmon_id = "5910c0ba0e42840004f6ea7c"
    config.intermedio_id_1 = "5910c0b90e42840004f6e9ee"
    config.intermedio_id_2 = "5910c0ba0e42840004f6ea7b"
    config.host = 'integra17.ing.puc.cl'
    config.port = '22'
    config.ftp_user = 'grupo5'
    config.ftp_pass = 'ARBQm2M5EwZn4GD3'
    config.my_id = "5910c0910e42840004f6e684"
    config.time_zone = 'Santiago'

    # DEVELOPMENT
    # config.secret = 'W1gCjv8gpoE4JnR'
    # config.base_route_oc = "https://integracion-2017-dev.herokuapp.com/oc/"
    # config.base_route_bodega = "https://integracion-2017-dev.herokuapp.com/bodega/" # desarrollo
    # config.base_route_banco = "https://integracion-2017-dev.herokuapp.com/banco/"
    # config.base_route_factura = "https://integracion-2017-dev.herokuapp.com/sii/"
    # config.banco_id = "590baa00d6b4ec0004902471"
    # config.recepcion_id = "590baa76d6b4ec00049028b1"
    # config.despacho_id = "590baa76d6b4ec00049028b2"
    # config.pulmon_id = "590baa76d6b4ec00049029dc"
    # config.intermedio_id_1 = "590baa76d6b4ec00049028b3"
    # config.intermedio_id_2 = "590baa76d6b4ec00049029db"
    # config.host = 'integra17dev.ing.puc.cl'
    # config.port = '22'
    # config.ftp_user = 'grupo5'
    # config.ftp_pass = 'jR4mgD9tb6BNk2WM'
    # config.my_id = "590baa00d6b4ec0004902466"
    # config.time_zone = 'Santiago'

  end
end
