class ProductController < ApplicationController


    def index
        @products = Product.all
        render json: {[
{
      "sku": "3",
      "name": "Maíz",
      "price": "117",
      "stock": "0"},
    {
      "sku": "5",
      "name": "Yogur",
      "price": "428",
      "stock": "0"},
    {
      "sku": "7",
      "name": "Leche",
      "price": "290",
      "stock": "0"},
    {
      "sku": "9",
      "name": "Carne",
      "price": "350",
      "stock": "0"},
    {
      "sku": "11",
      "name": "Margarina",
      "price": "247",
      "stock": "0"},
    {
      "sku": "15",
      "name": "Avena",
      "price": "276",
      "stock": "0"},
    {
      "sku": "17",
      "name": "Cereal arroz",
      "price": "821",
      "stock": "0"},
    {
      "sku": "22",
      "name": "Mantequilla",
      "price": "336",
      "stock": "0"},
    {
      "sku": "25",
      "name": "Azúcar",
      "price": "93",
      "stock": "0"},
    {
      "sku": "52",
      "name": "Harina Integral",
      "price": "410",
      "stock": "0"},
    {
      "sku": "56",
      "name": "Hamburguesas de Pollo",
      "price": "479",
      "stock": "0"}
      ]
    }

    end




end
