require 'sinatra'
require 'alexa_rubykit'
require 'json'
require 'open-uri'
require 'rss'
require 'alexa_verifier'

post '/metastatus' do
  begin
    body = request.body.read
    verify_alexa(body)

    query_json = JSON.parse(body.to_s)
    query = AlexaRubykit.build_request(query_json)

    case query.type
    when 'INTENT_REQUEST'
      intent_request(query)
    else
      ask_for_service_name
    end
  rescue AlexaVerifier::VerificationError => error
    status 400
      ""
  end
end

get '/github' do
  status_of_github
end

get '/digital_ocean' do
  status_of_digital_ocean
end

get '/twitter' do
  status_of_twitter
end

private

def verify_alexa body
  verifier = AlexaVerifier.new

  verifier.verify!(
    request.env['HTTP_SIGNATURECERTCHAINURL'],
    request.env['HTTP_SIGNATURE'],
    body
  )
end

def ask_for_service_name is_new = true
  message = "What service would you like to check?"
  message = "I'm sorry I did not get what service you meant. " + message unless is_new
  respond message, false
end

def provide_info_and_ask_for_service_name is_new = true
  message = "Betta Status is a simple tool for checking if your favorite developer tools are up and running without issues. We currently support GitHub and Digital Ocean. "
  message += "What service would you like to check?"
  respond message, false
end

def intent_request query
  case query.intent['name']
  when "StatusCheck"
    service = query.slots['Service']['value']

    if service == nil
      ask_for_service_name(query.session.new)
    else
      respond status_of(service)
    end
  when "AMAZON.HelpIntent"
    provide_info_and_ask_for_service_name(query.session.new)
  when "AMAZON.StopIntent", "AMAZON.CancelIntent"
    respond nil
  end
end

def status_of service
  case service
  when "github", "git hub", "git hub dot com", "github dot com"
    status_of_github
  when "digitalocean", "digital ocean"
    status_of_digital_ocean
  when "twitter"
    status_of_twitter
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

def status_of_twitter
  response = open('https://api.io.watchmouse.com/synth/current/39657/folder/7617?fields=cur;info').read
  status = JSON.parse(response)

  errors = status['result'].map do |item|
    next if item['cur']['status'] == 0
    item['info']['name']
  end.compact


  if errors.empty?
    "Twitter is fully operational"
  else
    "Twitter is having some issues. The affected endpoints are: #{errors.join(', ')}"
  end
end

def respond answer, end_session = true
  response = AlexaRubykit::Response.new
  response.say_response(answer)
  response.build_response(end_session)
end
