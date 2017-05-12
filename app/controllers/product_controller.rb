class ProductController < ApplicationController


    def index
        @products = Product.all
        render json: {"productos": [
{
    "sku": "",
    "name": "piedra",
    "price": "4500",
    "stock": ""
},{
    "sku": "",
    "name": "papel",
    "price": "500",
    "stock": ""}]}

    end




end
