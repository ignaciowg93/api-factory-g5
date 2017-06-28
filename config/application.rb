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
    #config.cola_ofertas = "amqp://kjyuymto:xgbHFOEpYvNbS9Gxb-3pBAfqf7mD-Dmp@fish.rmq.cloudamqp.com/kjyuymto"


    config.fb_images = {
    "sku3"	=> "http://ve.emedemujer.com/wp-content/uploads/sites/2/2016/11/harina-de-ma%C3%ADz-660x400.jpg",

    "sku5" => "https://c1.staticflickr.com/1/91/206868656_ed0c78d9ec_b.jpg",

    "sku7"	=> "http://www.smartia.digital/sm-upload/2017/06/Paulina%20Monarrez%20Dia%20Mundial%20de%20la%20leche%20(4).jpg",

    "sku9"	=> "https://calidadcarnecita.files.wordpress.com/2012/02/blog-curro1.jpg",

    "sku11"	=> "https://i.ytimg.com/vi/Vrbfyax_T6s/hqdefault.jpg",

    "sku15"	=> "http://nutricionsinmas.com/wp-content/uploads/2015/09/saco-de-avena-580x400.jpg",

    "sku17"	=> "https://previews.123rf.com/images/dpimborough/dpimborough1407/dpimborough140700016/29816145-Puffed-cereal-de-arroz-y-az-car-pasta-de-arroz-que-se-forma-en-las-formas-de-arroz-Foto-de-archivo.jpg",

    "sku22"	=> "https://ichef-1.bbci.co.uk/news/ws/624/amz/worldservice/live/assets/images/2016/01/08/160108125918_butter_624x351_thinkstock_nocredit.jpg",

    "sku25"	=> "http://s3.amazonaws.com/lahora-cl-bkt/wp-content/uploads/2016/11/01175453/azucar.jpg",

    "sku52"	=> "http://static.vix.com/es/sites/default/files/styles/large/public/imj/vivirsalud/H/Harina-refinada-o-harina-integral-1.jpg?itok=_So-PaeW",

    "sku56"	=> "https://t1.uc.ltmcdn.com/images/1/3/2/img_como_hacer_hamburguesas_de_pollo_33231_600.jpg",
    }

    # # DEVELOPMENT
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
    config.cola_ofertas = "amqp://hwlepmrs:uPDTlJqmGIB95x7jdafvpBMBb-pK7PPV@fish.rmq.cloudamqp.com/hwlepmrs"

  end
end
