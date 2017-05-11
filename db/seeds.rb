# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

p3 = Product.create(sku: '3', name: 'Maíz', processed: 0, price: 117, lot: 30, ingredients: , dependent: 1, time: 1.726)
p5 = Product.create(sku: '5', name: 'Yogur', processed: 1, price: 428, lot: 600, ingredients: 3, dependent: 0, time: 3.191)
p7 = Product.create(sku: '7', name: 'Leche', processed: 0, price: 290, lot: 1000, ingredients: , dependent: 8, time: 1.441)
p9 = Product.create(sku: '9', name: 'Carne', processed: 0, price: 350, lot: 620, ingredients: , dependent: 1, time: 2.846)
p11 = Product.create(sku: '11', name: 'Margarina', processed: 1, price: 247, lot: 900, ingredients: 1, dependent: 0, time: 3.074)
p15 = Product.create(sku: '15', name: 'Avena', processed: 0, price: 276, lot: 480, ingredients: , dependent: 1, time: 1.430)
p17 = Product.create(sku: '17', name: 'Cereal Arroz', processed: 1, price: 821, lot: 1000, ingredients: 3, dependent: 0, time: 1.158)
p22 = Product.create(sku: '22', name: 'Mantequilla', processed: 1, price: 336, lot: 400, ingredients: 1, dependent: 1, time: 1.832)
p25 = Product.create(sku: '25', name: 'Azúcar', processed: 0, price: 93, lot: 560, ingredients: , dependent: 6, time: 2.785)
p52 = Product.create(sku: '52', name: 'Harina Integral', processed: 1, price: 410, lot: 890, ingredients: 2, dependent: 2, time: 1.506)
p56 = Product.create(sku: '56', name: 'Hamburguesas de Pollo', processed: 1, price: 479, lot: 620, ingredients: 2, dependent: , time: 1.533)


p5.supplies.create(sku: '49', requierment: 228, sellers: [3,2,1], time: [1.846, 2.368, 2.046])
p5.supplies.create(sku: '6', requierment: 228, sellers: [8,6,2], time: [2.481, 2.916, 2.123])
p5.supplies.create(sku: '41', requierment: 194, sellers: [7,3,2], time: [2.091, 1.460, 1.687])
p11.supplies.create(sku: '4', requierment: 828, sellers: [8,6,4], time: [1.205, 2.615, 2.713])
p17.supplies.create(sku: '25', requierment: 360, sellers: [7,5,3,1], time: [0.945, 2.785, 3.254, 0.821])
p17.supplies.create(sku: '20', requierment: 350, sellers: [8,6,4,2], time: [2.258, 3.356, 1.955, 3.475])
p17.supplies.create(sku: '13', requierment: 290, sellers: [7,3,1], time: [1.304, 3.164, 3.256])
p22.supplies.create(sku: '6', requierment: 380, sellers: [8,6,2], time: [2.481, 2.916, 2.123])
p52.supplies.create(sku: '8', requierment: 1000, sellers: [6,4,2], time: [3.773, 2.531, 1.516])
p52.supplies.create(sku: '38', requierment: 20, sellers: [8,7], time: [3.462, 3.128])
p56.supplies.create(sku: '1', requierment: 935, sellers: [3,1], time: [3.605, 2.176])
p56.supplies.create(sku: '26', requierment: 65, sellers: [8,6,4,2], time: [3.059, 1.092, 1.242, 2.609])
