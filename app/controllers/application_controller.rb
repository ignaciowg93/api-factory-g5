class ApplicationController < ActionController::API
	def hello
		render html: 'Hello World!'
	end
end
