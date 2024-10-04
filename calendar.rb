# http://www.rubydoc.info/github/google/google-api-ruby-client/Google/Apis/CalendarV3
require 'googleauth'
require 'google/apis/calendar_v3'
require 'dotenv/load'
require 'pry'
require 'active_support/time'

class Calendar

  def initialize(logger)
    authorize
    @logger = logger
  end

  def service
    @service
  end

  def events(reload=false)
    # NOTE: This is just for demonstration purposes and not complete.
    # If you have more than 2500 results, you'll need to get more than    
    # one set of results.
    @events = nil if reload
    @events ||= service.list_events(calendar_id, max_results: 2500).items
  end

  def create_event(session)
    existing = existing_event(session)

    starts_at = Google::Apis::CalendarV3::EventDateTime.new(date_time: DateTime.parse(session.startsAt))
    ends_at = Google::Apis::CalendarV3::EventDateTime.new(date_time: DateTime.parse(session.endsAt))
    title = session.sessionName
    description = format_description(session)

    event = Google::Apis::CalendarV3::Event.new(start: starts_at,
                                                end: ends_at,
                                                summary: title,
                                                description: description,
                                                location: location_address)

    if existing
      if session.isCancelled
        @logger.info("Deleting event #{existing.id}: #{title} at #{starts_at.date_time.localtime}")
        service.delete_event(calendar_id, existing.id)
      else
        @logger.info("Updating event #{existing.id}: #{title} at #{starts_at.date_time.localtime}")
        service.update_event(calendar_id, existing.id, event)
      end
    elsif !session.isCancelled
      @logger.info("Creating event #{title} at #{starts_at.date_time.localtime}")
      service.insert_event(calendar_id, event)
    end
  end

  private

  def format_description(session)
    "Sign up link: #{session.link} \n" +
      "Location: #{session.location} \n" +
      "Instructor: #{session.teacher} \n\n" +
      "#{session.level}"
  end

  def existing_event(session)
    events.find { |e| e.description.include?(session.link) }
  end

  def calendar_id
    @calendar_id ||= ENV.fetch("GOOGLE_CALENDAR_ID", "")
  end

  def location_address
    @location_address ||=ENV.fetch("LOCATION_ADDRESS", "")
  end

  def authorize
    calendar = Google::Apis::CalendarV3::CalendarService.new
    calendar.client_options.application_name = 'Momence Calendar Sync' # This is optional
    calendar.client_options.application_version = '0.1.0' # This is optional


    scopes = [Google::Apis::CalendarV3::AUTH_CALENDAR]
    calendar.authorization = Google::Auth.get_application_default(scopes)

    @service = calendar
  end
end
