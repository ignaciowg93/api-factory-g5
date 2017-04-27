class ProductController < ApplicationController


    def index
        @products = Product.all
        render json: {sku: "" , nombre: "piedra" , precio:4500 , stock: "" }

    end

    

    
end
