# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

p3 = Product.create(sku: '3', name: 'Maíz', processed: 0, price: 117, lot: 30, ingredients: 0, dependent: 1, time: 1.726)
p5 = Product.create(sku: '5', name: 'Yogur', processed: 1, price: 428, lot: 600, ingredients: 3, dependent: 0, time: 3.191)
p7 = Product.create(sku: '7', name: 'Leche', processed: 0, price: 290, lot: 1000, ingredients: 0, dependent: 8, time: 1.441)
p9 = Product.create(sku: '9', name: 'Carne', processed: 0, price: 350, lot: 620, ingredients: 0, dependent: 1, time: 2.846)
p11 = Product.create(sku: '11', name: 'Margarina', processed: 1, price: 247, lot: 900, ingredients: 1, dependent: 0, time: 3.074)
p15 = Product.create(sku: '15', name: 'Avena', processed: 0, price: 276, lot: 480, ingredients: 0, dependent: 1, time: 1.430)
p17 = Product.create(sku: '17', name: 'Cereal Arroz', processed: 1, price: 821, lot: 1000, ingredients: 3, dependent: 0, time: 1.158)
p22 = Product.create(sku: '22', name: 'Mantequilla', processed: 1, price: 336, lot: 400, ingredients: 1, dependent: 1, time: 1.832)
p25 = Product.create(sku: '25', name: 'Azúcar', processed: 0, price: 93, lot: 560, ingredients: 0, dependent: 6, time: 2.785)
p52 = Product.create(sku: '52', name: 'Harina Integral', processed: 1, price: 410, lot: 890, ingredients: 2, dependent: 2, time: 1.506)
p56 = Product.create(sku: '56', name: 'Hamburguesas de Pollo', processed: 1, price: 479, lot: 620, ingredients: 2, dependent: 0, time: 1.533)


p5.supplies.create(sku: '49', requierment: 228, seller: '3', time: 1.846)
p5.supplies.create(sku: '49', requierment: 228, seller: '2', time: 2.368)
p5.supplies.create(sku: '49', requierment: 228, seller: '1', time: 2.046)
p5.supplies.create(sku: '6', requierment: 228, seller: '8', time: 2.481)
p5.supplies.create(sku: '6', requierment: 228, seller: '6', time: 2.916)
p5.supplies.create(sku: '6', requierment: 228, seller: '2', time: 2.123)
p5.supplies.create(sku: '41', requierment: 194, seller: '7', time: 2.091)
p5.supplies.create(sku: '41', requierment: 194, seller: '3', time: 1.460)
p5.supplies.create(sku: '41', requierment: 194, seller: '2', time: 1.687)

p11.supplies.create(sku: '4', requierment: 828, seller: '8', time: 1.205)
p11.supplies.create(sku: '4', requierment: 828, seller: '6', time: 2.615)
p11.supplies.create(sku: '4', requierment: 828, seller: '4', time: 2.713)

p17.supplies.create(sku: '25', requierment: 360, seller: '7', time: 0.945)
p17.supplies.create(sku: '25', requierment: 360, seller: '5', time: 2.785)
p17.supplies.create(sku: '25', requierment: 360, seller: '3', time: 3.254)
p17.supplies.create(sku: '25', requierment: 360, seller: '1', time: 0.821)
p17.supplies.create(sku: '20', requierment: 350, seller: '8', time: 2.258)
p17.supplies.create(sku: '20', requierment: 350, seller: '6', time: 3.356)
p17.supplies.create(sku: '20', requierment: 350, seller: '4', time: 1.955)
p17.supplies.create(sku: '20', requierment: 350, seller: '2', time: 3.475)
p17.supplies.create(sku: '13', requierment: 290, seller: '7', time: 1.304)
p17.supplies.create(sku: '13', requierment: 290, seller: '3', time: 3.164)
p17.supplies.create(sku: '13', requierment: 290, seller: '1', time: 3.256)

p22.supplies.create(sku: '6', requierment: 380, seller: '8', time: 2.481)
p22.supplies.create(sku: '6', requierment: 380, seller: '6', time: 2.916)
p22.supplies.create(sku: '6', requierment: 380, seller: '2', time: 2.123)

p52.supplies.create(sku: '8', requierment: 1000, seller: '6', time: 3.773)
p52.supplies.create(sku: '8', requierment: 1000, seller: '4', time: 2.531)
p52.supplies.create(sku: '8', requierment: 1000, seller: '2', time: 1.516)
p52.supplies.create(sku: '38', requierment: 20, seller: '8', time: 3.462)
p52.supplies.create(sku: '38', requierment: 20, seller: '7', time: 3.128)

p56.supplies.create(sku: '1', requierment: 935, seller: '3', time: 3.605)
p56.supplies.create(sku: '1', requierment: 935, seller: '1', time: 2.176)
p56.supplies.create(sku: '26', requierment: 65, seller: '8', time: 3.059)
p56.supplies.create(sku: '26', requierment: 65, seller: '6', time: 1.092)
p56.supplies.create(sku: '26', requierment: 65, seller: '4', time: 1.242)
p56.supplies.create(sku: '26', requierment: 65, seller: '2', time: 2.609)

Client.create(name: "5910c0910e42840004f6e680", url: "http://integra17-1.ing.puc.cl/", token: "", gnumber: "1") #prod
Client.create(name: "590baa00d6b4ec0004902463", url: "http://integra17-2.ing.puc.cl/", token: "", gnumber: "2")
Client.create(name: "", url: "http://integra17-3.ing.puc.cl/", token: "", gnumber: "3")
Client.create(name: "", url: "http://integra17-4.ing.puc.cl/", token: "", gnumber: "4")
Client.create(name: "590baa00d6b4ec0004902466", url: "http://integra17-5.ing.puc.cl/", token: "", gnumber: "5")
Client.create(name: "", url: "http://integra17-6.ing.puc.cl/", token: "", gnumber: "6")
Client.create(name: "590baa00d6b4ec0004902468", url: "http://dev.integra17-7.ing.puc.cl/", token: "", gnumber: "7")
Client.create(name: "", url: "http://integra17-8.ing.puc.cl/", token: "", gnumber: "8")


Spree::Core::Engine.load_seed if defined?(Spree::Core)
Spree::Auth::Engine.load_seed if defined?(Spree::Auth)
