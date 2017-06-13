class ClientsController < ApplicationController

	def all
		lista = []
		clients = Client.all
		clients.each do |client|
			lista << client.url
		end
		render :html => lista
	end
end
