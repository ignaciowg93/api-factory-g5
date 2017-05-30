require 'rufus/scheduler'
require "http"

def produce_and_supplying2(cantidad, sku)
  puts "Me llamaron, soy produce and supplying 2"
end

def move_to_intermedio(cantidad, sku)
  puts "Soy move_to_intermedio"
end

scheduler = Rufus::Scheduler.new
por_producir = Array.new

scheduler.every '10s' do
  # rake "mails:monthly_report_mail"
  Product.all.each do |prod|
    stock = (Stock.find_by sku: prod.sku).totalAmount
    puts("\nSKU: #{prod.sku}, #{stock}")
    if stock < 200
      por_producir.push([cantidad, sku])
    else
      puts("Queda #{prod.name}. No hacer nada")
    end
  end
  # Ahora procedemos pedir efectivamente lo que pusimos en nuestra lista
  tiempos_retiro = Array.new
  por_producir.each do |pedido|
    tiempos_retiro.push(produce_and_supplying2(pedido[0], pedido[1]), pedido[0], pedido[1])
  end
  #ordenar según tiempos retiro
  tiempos_retiro.sort!{|a,b| a[0] <=> b[0]}

  lista_retiro.each do |por_retirar|
    while por_retirar[0] < Time.now
      sleep(300) # vuelvo a preguntar en 5 minutos
    end
    move_to_intermedio(por_retirar[1], por_retirar[2]) # (cantidad, sku)
  end
end
