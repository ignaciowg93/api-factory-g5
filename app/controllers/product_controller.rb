class ProductController < ApplicationController


    def index
        @products = Products.all
        render json: {{sku: "" , name: "piedra" , price: "4500" , stock: "" },
        			  {sku: "" , name: "madera" , price: "3000" , stock: "" }}, status: 200

    end

    

    
end
