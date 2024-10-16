require 'active_support/logger_silence'
require 'active_support/broadcast_logger'
require 'dotenv/load'
require 'json'
require 'logger'
require 'net/http'
require 'optparse'
require 'ostruct'
require 'pry'
require_relative 'calendar'

LEVELS = {
  "debug" => Logger::DEBUG,
  "info" => Logger::INFO,
  "warn" => Logger::WARN,
  "error" => Logger::ERROR,
  "fatal" => Logger::FATAL,
  "unknown" => Logger::UNKNOWN,
}

options = { env: ['.env'] }
OptionParser.new do |opt|
  opt.on('--env=ENVS') { |o| options[:env] = o.split(",") }
  opt.on('--stdout=LEVEL') { |o| options[:stdout] = LEVELS[o] }
end.parse!

file_logger = Logger.new('sync.log', 'weekly')
logger = if options[:stdout]
           stdout_logger = Logger.new(STDOUT, level: options[:stdout])
           ActiveSupport::BroadcastLogger.new(stdout_logger, file_logger)
         else
           file_logger
         end

options[:env].each do |env|
  Dotenv.load(env, overwrite: true)
  host_id = ENV["MOMENCE_HOST_ID"]
  logger.info("Updating host #{host_id} with #{env}")

  uri = URI("https://readonly-api.momence.com/host-plugins/host/#{host_id}/host-schedule/sessions")
  data = Net::HTTP.get(uri)
  session_array = JSON.parse(data, object_class: OpenStruct).payload
  calendar = Calendar.new(logger)

  session_array.each do |session|
    next if %w[course semester].include?(session.type)

    calendar.create_event(session)
  end

  calendar.delete_remaining_events
end
