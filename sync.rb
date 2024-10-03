require 'json'
require 'net/http'
require 'ostruct'

uri = URI('https://readonly-api.momence.com/host-plugins/host/30822/host-schedule/sessions')
data = Net::HTTP.get(uri)
session_array = JSON.parse(data, object_class: OpenStruct).payload
session_array.each do |session|
  puts session.sessionName
end

