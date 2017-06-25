# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

run Rails.application

if defined?(PhusionPassenger) # otherwise it breaks rake commands if you put this in an initializer
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
       # We’re in a smart spawning mode
       # Now is a good time to connect to RabbitMQ
       $rabbitmq_connection = Bunny.new("amqp://hwlepmrs:uPDTlJqmGIB95x7jdafvpBMBb-pK7PPV@fish.rmq.cloudamqp.com/hwlepmrs")
       $rabbitmq_connection.start

       $rabbitmq_channel    = $rabbitmq_connection.create_channel
    end
  end

  PhusionPassenger.on_event(:stopping_worker_process) do
    if $rabbitmq_connection
      $rabbitmq_connection.close
    end
  end
end
