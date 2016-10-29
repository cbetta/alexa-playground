require 'sinatra'
require 'alexa_rubykit'

post '/metastatus' do
  puts params.inspect
  response = AlexaRubykit::Response.new
  response.add_speech('Ruby is running ready!')
  response.build_response
end
