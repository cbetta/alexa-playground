require 'sinatra'
require 'alexa_rubykit'

post '/metastatus' do
  query_json = JSON.parse(request.body.read.to_s)
  query = AlexaRubykit.build_request(query_json)

  process(query) if query.type == 'INTENT_REQUEST'
end

private

def process query
  case query.intent['name']
  when "StatusCheck"
    service = query.slots['Service']['value']
    status_check service
  end
end

def status_check service
  response = AlexaRubykit::Response.new
  response.add_speech("Checking #{service}")
  response.build_response
end
