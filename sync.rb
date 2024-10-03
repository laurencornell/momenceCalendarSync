require 'json'
require 'net/http'
require 'ostruct'
require 'pry'
require_relative 'calendar'

uri = URI("https://readonly-api.momence.com/host-plugins/host/#{ENV["MOMENCE_HOST_ID"]}/host-schedule/sessions")
data = Net::HTTP.get(uri)
session_array = JSON.parse(data, object_class: OpenStruct).payload
calendar = Calendar.new
binding.pry

session_array.each do |session|
  next if %w[course semester].include?(session.type)

  calendar.create_event(session)
end
