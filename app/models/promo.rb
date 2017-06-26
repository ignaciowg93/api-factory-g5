require 'bunny'
require 'rubygems'
require 'rest-client'

class Promo < ApplicationRecord

    validates :sku, :precio, :inicio, :fin, :codigo, presence: true

    def self.revisar_ofertas()
        client = Twitter::REST::Client.new do |config|
            config.consumer_key        = "iExeOPmt0NyO5Q5ftB0JSEuCi"
            config.consumer_secret     = "dPfoPZpKc08CPxwIWpnK2RsGKRGwO5nN6nIMyWZxM0e1Ph5GWN"
            config.access_token        = "879037547095220224-Smr6ICButdBqCvGBJnVua8DdzoZlHaA"
            config.access_token_secret = "kyewGgZ9KBqrjyF8eNH7viS7P3qDkdzST0Z24FkCjkJPP"
        end
        STDOUT.sync = true
        conn = Bunny.new("amqp://hwlepmrs:uPDTlJqmGIB95x7jdafvpBMBb-pK7PPV@fish.rmq.cloudamqp.com/hwlepmrs")
        conn.start

        ch = conn.create_channel
        q  = ch.queue("ofertas", :auto_delete => true)
        x  = ch.default_exchange

        cortar = 0
        q.subscribe do |delivery_info, metadata, payload|
            puts payload
            payload = JSON.parse(payload)
            #msg_tp = "MENSAJE DE PRUEBA DESDE API"
            if payload["publicar"]
                product = (Product.find_by sku: payload["sku"])
                if product != nil
                    Promo.create(sku: payload["sku"], precio: payload["precio"], inicio: payload["inicio"], fin: payload["fin"], codigo: payload["codigo"])
                    product = product.name
                    to_publi = "Ahora+nuestro+#{product.split(' ').join('+')}+a+tan+solo+$#{payload["precio"]}.+Aprovecha+esta+oferta+con+el+codigo+#{payload["codigo"]}!"
                    publi = HTTP.post("https://graph.facebook.com/307193066399367/feed?message=#{to_publi}&access_token=EAADxlJnEikwBAMhlvuWmPkZAX6kWLDhZACdjf7O1QKfzHwd3UBMqZCD76yObHWGZCAhvWhGOG9hHe9Bz4nu4m8hspeCkt7I5zWmXm0IPzTmmiZAWNkpkSSLtyopmv3RjGEPk24ZCg6rD8kpO76oen3ZCkWhEj391bHXVXXvnxNvF8OcgVTtLzep")
                    to_publi_tweet = "Ahora nuestro #{product} a tan solo $#{payload["precio"]}. Aprovecha esta oferta con el codigo #{payload["codigo"]}!"
                    publi_twitter = client.update(to_publi_tweet)
                    #client.update_with_media("I'm tweeting with @gem!", File.new("/path/to/media.png"))
                    puts publi
                end
            else
            puts("Producto no es nuestro")
            end
            sleep(5)
        end
        sleep 1.0
        ch.close
        conn.close
    end
end
