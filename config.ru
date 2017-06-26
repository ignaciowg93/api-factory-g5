# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

run Rails.application

# if defined?(PhusionPassenger) # otherwise it breaks rake commands if you put this in an initializer
#   PhusionPassenger.on_event(:starting_worker_process) do |forked|
#     if forked
#        # We’re in a smart spawning mode
#        # Now is a good time to connect to RabbitMQ
#        $rabbitmq_connection = Bunny.new("amqp://hwlepmrs:uPDTlJqmGIB95x7jdafvpBMBb-pK7PPV@fish.rmq.cloudamqp.com/hwlepmrs")
#        $rabbitmq_connection.start

#        $rabbitmq_channel    = $rabbitmq_connection.create_channel

#         q  = $rabbitmq_channel.queue("ofertas", :auto_delete => true)
#    			x  = $rabbitmq_channel.default_exchange


#    			q.subscribe do |delivery_info, metadata, payload|
#    			  puts payload
#    			  payload = JSON.parse(payload)
#    			  #msg_tp = "MENSAJE DE PRUEBA DESDE API"
#    			  if payload["publicar"]
#    					product = (Product.find_by sku: payload["sku"]).name
#    					to_publi = "Ahora+nuestro+sku+#{payload["sku"]}+a+tan+solo+$#{payload["precio"]}.+Aprovecha+esta+oferta+con+el+codigo+#{payload["codigo"]}!"
#    			    publi = HTTP.post("https://graph.facebook.com/307193066399367/feed?message=#{to_publi}&access_token=EAADxlJnEikwBAMhlvuWmPkZAX6kWLDhZACdjf7O1QKfzHwd3UBMqZCD76yObHWGZCAhvWhGOG9hHe9Bz4nu4m8hspeCkt7I5zWmXm0IPzTmmiZAWNkpkSSLtyopmv3RjGEPk24ZCg6rD8kpO76oen3ZCkWhEj391bHXVXXvnxNvF8OcgVTtLzep")
#    			    puts publi
#    			  end
#    			  sleep(5)
#         end
#     end
#   end
#   PhusionPassenger.on_event(:stopping_worker_process) do
#     if $rabbitmq_connection
#         $rabbitmq_connection.close
#     end
#   end
# end
