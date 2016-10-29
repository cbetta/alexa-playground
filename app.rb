require 'sinatra'
require 'alexa_rubykit'

get '/metastatus' do
  response = AlexaRubykit::Response.new
  response.add_speech('Ruby is running ready!')
  response.build_response
end
