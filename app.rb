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
    respond status_of(service)

  end
end

def status_of service
  case service
  when "github"
    result = open('https://status.github.com/api/status.json').read
    status = JSON.parse(result)['status']
    "The status of GitHub is #{status}"
  end
end

def respond answer
  response = AlexaRubykit::Response.new
  response.add_speech(answer)
  response.build_response
end
