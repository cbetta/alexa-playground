require 'sinatra'
require 'alexa_rubykit'

post '/metastatus' do
  query_json = JSON.parse(request.body.read.to_s)
  query = AlexaRubykit.build_request(query_json)

  process(query) if query.type == 'StatusCheck'
end

private

def process query
  response = AlexaRubykit::Response.new
  puts query.slots.inspect
  response.add_speech('Checking now')
  response.build_response
end
