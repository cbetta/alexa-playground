require 'sinatra'
require 'alexa_rubykit'
require 'json'
require 'open-uri'

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
    status_of_github
  when "digital ocean"
    "Sorry I am not set up to deal with Digital Ocean just yet"
  end
end

def status_of_github
  result = open('https://status.github.com/api/last-message.json').read
  status = JSON.parse(result)
  level = status['status']
  body = status['body']

  case level
  when "good"
    "GitHub is fully operational. #{body}"
  else
    "GitHub is experiencing some #{level} issues. #{body}"
  end
end


def respond answer
  response = AlexaRubykit::Response.new
  response.add_speech(answer)
  response.build_response
end
