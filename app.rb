require 'sinatra'
require 'alexa_rubykit'
require 'json'
require 'open-uri'
require 'rss'

post '/metastatus' do
  query_json = JSON.parse(request.body.read.to_s)
  query = AlexaRubykit.build_request(query_json)

  case query.type
  when 'INTENT_REQUEST'
    intent_request(query)
  else
    ask_for_service_name
  end
end

get '/github' do
  respond status_of('git hub')
end

get '/digital_ocean' do
  status_of_digital_ocean
end

private

def ask_for_service_name is_new = true
  message = "What service would you like to check?"
  message = "I'm sorry I did not get what service you meant. " + message unless is_new
  respond message, false
end

def intent_request query
  case query.intent['name']
  when "StatusCheck"
    puts query.slots.inspect
    service = query.slots['Service']['value']

    if service == nil
      ask_for_service_name(query.session.new)
    else
      respond status_of(service)
    end
  end
end

def status_of service
  case service
  when "github", "git hub", "git hub dot com", "github dot com"
    status_of_github
  when "digitalocean", "digital ocean"
    status_of_digital_ocean
  when "stop"
    nil
  else
    "Service not recognised. We currently support GitHub and Digital ocean only"
  end
end

def status_of_github
  response = open('https://status.github.com/api/last-message.json').read
  status = JSON.parse(response)
  level = status['status']
  body = status['body']

  case level
  when "good"
    "GitHub is fully operational. #{body}"
  else
    "GitHub is experiencing some #{level} issues. #{body}"
  end
end

def status_of_digital_ocean
  page = open('https://status.digitalocean.com/').read
  rss =  open('https://status.digitalocean.com/rss').read
  feed = RSS::Parser.parse(rss)
  latest_update = feed.items.first.title

  if page.include?('All Systems Operational')
    "Digital Ocean is fully operational. The latest update is: #{latest_update}"
  else
    "Digital Ocean is having some issues. The latest update is: #{latest_update}"
  end
end

def respond answer, end_session = true
  response = AlexaRubykit::Response.new
  response.say_response(answer)
  response.build_response(end_session)
end
