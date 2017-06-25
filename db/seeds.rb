# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require "http"
require 'digest'

# def generate_header(data)
#   hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), Rails.configuration.secret.encode("ASCII"), data.encode("ASCII"))
#   signature = Base64.encode64(hmac).chomp
#   auth_header = "INTEGRACION grupo5:" + signature
#   auth_header
# end
#
# def get_almacenes
#   data = "GET"
#   response = ""
#   loop do
#     response = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "almacenes")
#     break if response.code == 200
#   end
#   @almacenes = JSON.parse response.to_s
# end

# Revisa en todos los almacenes
# def get_stock(sku)
#     stock_final = 0
#     response = ""
#     @almacenes.each do |almacen|
#       data = "GET#{almacen["_id"]}"
#       loop do
#         response = HTTP.auth(generate_header(data)).headers(:accept => "application/json").get(Rails.configuration.base_route_bodega + "skusWithStock?almacenId=" + almacen["_id"])
#         break if response.code == 200
#       end
#       products = JSON.parse response.to_s
#       products.each do |product|
#         # Sku viene en id de producto
#           if product["_id"] == sku
#               stock_final += product["total"]
#           end
#       end
#
#     end
#     stock_final
# end

# YA ESTAN CREADOS

p3 = Product.create(sku: '3', name: 'Maíz', processed: 0, price: 117, sell_price: 140, lot: 30, ingredients: 0, dependent: 1, time: 1.726, stock_reservado: 0)
p5 = Product.create(sku: '5', name: 'Yogur', processed: 1, price: 428, sell_price: 513,lot: 600, ingredients: 3, dependent: 0, time: 3.191, stock_reservado: 0)
p7 = Product.create(sku: '7', name: 'Leche', processed: 0, price: 290, sell_price: 348,lot: 1000, ingredients: 0, dependent: 8, time: 1.441, stock_reservado: 0)
p9 = Product.create(sku: '9', name: 'Carne', processed: 0, price: 350, sell_price: 420,lot: 620, ingredients: 0, dependent: 1, time: 2.846, stock_reservado: 0)
p11 = Product.create(sku: '11', name: 'Margarina', processed: 1, price: 247, sell_price: 296,lot: 900, ingredients: 1, dependent: 0, time: 3.074, stock_reservado: 0)
p15 = Product.create(sku: '15', name: 'Avena', processed: 0, price: 276, sell_price: 331,lot: 480, ingredients: 0, dependent: 1, time: 1.430, stock_reservado: 0)
p17 = Product.create(sku: '17', name: 'Cereal Arroz', processed: 1, price: 821, sell_price: 985,lot: 1000, ingredients: 3, dependent: 0, time: 1.158, stock_reservado: 0)
p22 = Product.create(sku: '22', name: 'Mantequilla', processed: 1, price: 336, sell_price: 403,lot: 400, ingredients: 1, dependent: 1, time: 1.832, stock_reservado: 0)
p25 = Product.create(sku: '25', name: 'Azúcar', processed: 0, price: 93, sell_price: 111,lot: 560, ingredients: 0, dependent: 6, time: 2.785, stock_reservado: 0)
p52 = Product.create(sku: '52', name: 'Harina Integral', processed: 1, price: 410, sell_price: 492,lot: 890, ingredients: 2, dependent: 2, time: 1.506, stock_reservado: 0)
p56 = Product.create(sku: '56', name: 'Hamburguesas de Pollo', processed: 1, price: 479, sell_price: 574,lot: 620, ingredients: 2, dependent: 0, time: 1.533, stock_reservado: 0)

s51 = p5.supplies.create(sku: '49', requierment: 228, stock_reservado: 0)
# s51.sellers.create(seller: '3', time: 1.846)
# s51.sellers.create(seller: '2', time: 2.368)
# s51.sellers.create(seller: '1', time: 2.046)
s52 = p5.supplies.create(sku: '6', requierment: 228, stock_reservado: 0)
# s52.sellers.create(seller: '8', time: 2.481)
# s52.sellers.create(seller: '6', time: 2.916)
# s52.sellers.create(seller: '2', time: 2.123)
s53 = p5.supplies.create(sku: '41', requierment: 194, stock_reservado: 0)
# s53.sellers.create(seller: '7', time: 2.091)
# s53.sellers.create(seller: '3', time: 1.460)
# s53.sellers.create(seller: '2', time: 1.687)

s11 = p11.supplies.create(sku: '4', requierment: 828, stock_reservado: 0)
# s11.sellers.create(seller: '8', time: 1.205)
# s11.sellers.create(seller: '6', time: 2.615)
# s11.sellers.create(seller: '4', time: 2.713)

s171 = p17.supplies.create(sku: '25', requierment: 360, stock_reservado: 0)
# s171.sellers.create(seller: '7', time: 0.945)
# s171.sellers.create(seller: '5', time: 2.785)
# s171.sellers.create(seller: '3', time: 3.254)
# s171.sellers.create(seller: '1', time: 0.821)

s172 = p17.supplies.create(sku: '20', requierment: 350, stock_reservado: 0)
# s172.sellers.create(seller: '8', time: 2.258)
# s172.sellers.create(seller: '6', time: 3.356)
# s172.sellers.create(seller: '4', time: 1.955)
# s172.sellers.create(seller: '2', time: 3.475)

s173 = p17.supplies.create(sku: '13', requierment: 290, stock_reservado: 0)
# s173.sellers.create(seller: '7', time: 1.304)
# s173.sellers.create(seller: '3', time: 3.164)
# s173.sellers.create(seller: '1', time: 3.256)

s22 = p22.supplies.create(sku: '6', requierment: 380, stock_reservado: 0)
# s22.sellers.create(seller: '8', time: 2.481)
# s22.sellers.create(seller: '6', time: 2.916)
# s22.sellers.create(seller: '2', time: 2.123)

s521 = p52.supplies.create(sku: '8', requierment: 1000, stock_reservado: 0)
# s521.sellers.create(seller: '6', time: 3.773)
# s521.sellers.create(seller: '4', time: 2.531)
# s521.sellers.create(seller: '2', time: 1.516)

s522 = p52.supplies.create(sku: '38', requierment: 20, stock_reservado: 0)
# s521.sellers.create(seller: '8', time: 3.462)
# s521.sellers.create(seller: '7', time: 3.128)

s561 = p56.supplies.create(sku: '1', requierment: 935, stock_reservado: 0)
# s561.sellers.create(seller: '3', time: 3.605)
# s561.sellers.create(seller: '1', time: 2.176)

s562 = p56.supplies.create(sku: '26', requierment: 65, stock_reservado: 0)
# s562.sellers.create(seller: '8', time: 3.059)
# s562.sellers.create(seller: '6', time: 1.092)
# s562.sellers.create(seller: '4', time: 1.242)
# s562.sellers.create(seller: '2', time: 2.609)

# PROD
Client.create(name: "5910c0910e42840004f6e680", url: "http://integra17-1.ing.puc.cl/api/", token: "", gnumber: "1") #prod
Client.create(name: "5910c0910e42840004f6e681", url: "http://integra17-2.ing.puc.cl/", token: "", gnumber: "2")
Client.create(name: "5910c0910e42840004f6e682", url: "http://integra17-3.ing.puc.cl/", token: "", gnumber: "3")
Client.create(name: "5910c0910e42840004f6e683", url: "http://integra17-4.ing.puc.cl/", token: "", gnumber: "4")
Client.create(name: "5910c0910e42840004f6e684", url: "http://integra17-5.ing.puc.cl/", token: "", gnumber: "5")
Client.create(name: "5910c0910e42840004f6e685", url: "http://integra17-6.ing.puc.cl/", token: "", gnumber: "6")
Client.create(name: "5910c0910e42840004f6e686", url: "http://integra17-7.ing.puc.cl/", token: "", gnumber: "7")
Client.create(name: "5910c0910e42840004f6e687", url: "http://integra17-8.ing.puc.cl/", token: "", gnumber: "8")



# DEV
Client.find_by(gnumber: '1').update(name: "590baa00d6b4ec0004902462", url: "http://dev.integra17-1.ing.puc.cl/api/")
Client.find_by(gnumber: '2').update(name: "590baa00d6b4ec0004902463", url: "http://integra17-2.ing.puc.cl/")
Client.find_by(gnumber: '3').update(name: "590baa00d6b4ec0004902464", url: "http://integra17-3.ing.puc.cl/")
Client.find_by(gnumber: '4').update(name: "590baa00d6b4ec0004902465", url: "http://integra17-4.ing.puc.cl/")
Client.find_by(gnumber: '5').update(name: "590baa00d6b4ec0004902466", url: "http://integra17-5.ing.puc.cl/")
Client.find_by(gnumber: '6').update(name: "590baa00d6b4ec0004902467", url: "http://integra17-6.ing.puc.cl/")
Client.find_by(gnumber: '7').update(name: "590baa00d6b4ec0004902468", url: "http://dev.integra17-7.ing.puc.cl/")
Client.find_by(gnumber: '8').update(name: "590baa00d6b4ec0004902469", url: "http://dev.integra17-8.ing.puc.cl/")


# Reiniciar a 0 los stocks reservados
# Product.find_by(sku: '22').update(stock_reservado: 0)
# Product.find_by(sku: '7').update(stock_reservado: 0)

#Cambios cami
# PurchaseOrder.find_by(_id: '594378cfab8042000470337f').update(delivered_qt: 70)
# PurchaseOrder.find_by(_id: '594378cfab8042000470337f').update(status: 'finalizada')

# ProductionOrder.destroy_all(sku: "17")
# ProductionOrder.create(sku:"17", amount:1000, est_date:"2017-06-17T00:22:53.225Z")
