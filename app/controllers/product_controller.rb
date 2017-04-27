class ProductController < ApplicationController


    def index
        @products = Products.all
        render json: {sku: "" , name: "piedra" , price: "4500" , stock: ""}, status: 200

    end

    

    
end
