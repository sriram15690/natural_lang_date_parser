#require "natural_lang_date_parser/version"

module NaturalLangDateParser
	require "date"
require 'active_support/all'

EXISTING_PATTERNS  = {
	durations: 'minute|minutes|hour|hours|day|days|week|weeks|month|months|year|years',
	relative_tense: 'last|previous|next',
	explicit_dates: 'today|tomorrow|yesterday|day after tomorrow|day before yesterday',
	months: 'january|february|march|may|june|july|august|september|october|november|december',
	weekdays: 'sunday|monday|tuesday|wednesday|thursday|friday|saturday',
}

 class Parser
	 
	def initialize(datetime)
		@current_datetime = DateTime.now
		@input_params = datetime
	end
 	
 	# Formatting the input before parsing.
	def format_input
		# removing white spaces at the beginning and the end
		@input_params = @input_params.downcase.strip()
 	end

 	# Parsing the Input provided by the user.
 	def parse_input 
 		format_input

 		p "Input is #{@input_params}"
        #begin
			# check if the input refers to an explicit datetime like today etc
			if explicit_date? @input_params
				interpret_explicit_date @input_params
			# check if the input refers to relative input like next friday or next month etc
			elsif relative_date? @input_params
				interpret_relative_date @input_params
			# check if the input refers to a past of future date and interpret it
			elsif date = past_or_future_date(@input_params)
				date
			# Try Ruby Date Parser 
			else
				DateTime.parse(@input_params)
			end
 		#rescue
		#	p "Sorry!! Something went wrong. Pls. check and try again"	
        #end
 	end
	
	# check if the input refers to an explicit datetime like today etc
 	def explicit_date?(date)
 		!(/(?<relative_date>#{EXISTING_PATTERNS[:explicit_dates]})/.match(date)).nil?
 	end

 	def past_or_future_date date
 		# when date is of the form 2 weeks ago
 		if parsed_data = (/(?<quantity>\d+) (?<duration>#{EXISTING_PATTERNS[:durations]}) (?<tense>ago|later|after)*/.match(date))
 			calculate_datetime(parsed_data[:duration], parsed_data[:quantity].to_i,find_tense(parsed_data[:tense]))
		# when date is of the form in 3 hours 
		elsif parsed_data = (/(?<tense>after|in|before) (?<quantity>\d+) (?<duration>#{EXISTING_PATTERNS[:durations]})/.match(date))
			calculate_datetime(parsed_data[:duration], parsed_data[:quantity].to_i,find_tense(parsed_data[:tense]))
		else
			false
		end
 	end

 	# check whether date is of the form next friday or next month etc & return boolean
 	def relative_date? date
 		all_durations = EXISTING_PATTERNS[:weekdays] + EXISTING_PATTERNS[:months] + EXISTING_PATTERNS[:durations]
 		!(/(#{EXISTING_PATTERNS[:relative_tense]}) (#{all_durations})/.match(date)).nil? 
 	end

 	# asiigning values for few explicit dates like tomorrow, yesterday etc. 
 	def interpret_explicit_date date
 		case date
	 		when 'today'
	 			DateTime.now
			when 'tomorrow'
				1.days.from_now
			when 'yesterday'
				1.days.ago
			when 'day after tomorrow'
				2.days.from_now
			when 'day before yesterday'
				2.days.ago
			else
				nil
		end
	end
 	
 	# Parsing relative date like next friday or next month
 	def interpret_relative_date date
 		all_durations = EXISTING_PATTERNS[:weekdays] + EXISTING_PATTERNS[:months] + EXISTING_PATTERNS[:durations]
	 	relative_date = /(?<tense>#{EXISTING_PATTERNS[:relative_tense]}) (?<type>#{all_durations})(\s at)*/.match(date)

 		# Check if the user is referring to a weekday
	 	if weekday?(relative_date[:type])
 	  		if (relative_date[:tense] == 'next')
				date_of_next(relative_date[:type])
	  		else
	  			date_of_previous(relative_date[:type])
	  		end
	 	else
 			tense = (relative_date[:tense] == 'next') ? 'from_now' : 'ago'
	 		calculate_datetime(relative_date[:type], 1, tense)
	 	end
 	end


 	def find_tense data
 		if ['ago', 'before'].include? data
 			'ago'
		else
			'from_now'
		end
 	end
	 
	# returns if its a valid day of the week
	def weekday?(day)
		day && (EXISTING_PATTERNS[:weekdays].split('|').include? day)
	end
	 
	 # Return the next specific weekeday. Example: next tuesday
	def date_of_next(day)
	  day_required = DateTime.parse(day)
	  delta = day_required > DateTime.now ? 0 : 7
	  (day_required + delta)
	end
	 
	 # Return the previous specific weekeday. Example: previous tuesday
	def date_of_previous(day)
	  day_required = DateTime.parse(day)
	  delta = day_required < DateTime.now ? 0 : 7
	  (day_required - delta)
	end
	 
	# Defining the DateTime object based on parameters.
	def calculate_datetime(type, quantity, tense)
		# converting week to days  as ruby doesnt have explicit method for week.
		if type.singularize == 'week'
	 		type = 'days'
	 		quantity = quantity * 7
	 	end
		quantity.send(type).send(tense)
	 end
 end
end
