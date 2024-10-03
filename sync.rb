require 'json'
require 'net/http'
require 'ostruct'
require 'pry'
require_relative 'calendar'

env_files = ARGV
env_files = ['.env'] if env_files.empty?

env_files.each do |env|
  Dotenv.load(env, overwrite: true)
  host_id = ENV["MOMENCE_HOST_ID"]
  puts "Updating host #{host_id}"

  uri = URI("https://readonly-api.momence.com/host-plugins/host/#{host_id}/host-schedule/sessions")
  data = Net::HTTP.get(uri)
  session_array = JSON.parse(data, object_class: OpenStruct).payload
  calendar = Calendar.new

  session_array.each do |session|
    next if %w[course semester].include?(session.type)

    calendar.create_event(session)
  end
end
