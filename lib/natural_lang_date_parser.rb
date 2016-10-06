#require "natural_lang_date_parser/version"

module NaturalLangDateParser
	require "date"
require 'active_support/all'

EXISTING_PATTERNS  = {
	months: ['january','february','march','may','june','july','august','september', 'october','november','december'],
	days: ['sunday','monday','tuesday', 'wednesday','thursday','friday','saturday'],
	past: ["before","ago", 'yesterday', 'last','previous'],
	future: ['after','later','tomorrow','next', 'in']
}
 class NaturalDateParser
	 
	def initialize(datetime)
		@current_datetime = DateTime.now
		@input_params = datetime
		@formatted_params = nil
	end
 
	def format_input
		# removing white spaces at the beginning and the end
		@input_params.strip()
		@formatted_params = @input_params.split(" ").map {|x| x.downcase.singularize}
		# p @formatted_params
	 end
	 
	 def parse_input
		# sanitise the input before processing.
		format_input
		
		# check if its today 
		if @input_params == 'today'
				DateTime.now
		# check if its past 
		elsif !(@formatted_params & EXISTING_PATTERNS[:past]).empty?
			calculate_past_date
		# check if its future 
		elsif !(@formatted_params & EXISTING_PATTERNS[:future]).empty?
			calculate_future_date
		# Fallback to Ruby Date parser
		else 
			# replacing noon with 12pm. Further scenarios can be added and moved to a new method in future
			@input_params.gsub!(/noon/,'12pm')			
			DateTime.parse(@input_params)
		end
	rescue
		puts "Sorry!! Something went wrong while interpreting your input. Pls. check and try again."
    end

	 def calculate_past_date
		# storing the various parameters
		past_params = {
			past_type: nil,
			past_value: nil,
			date_type: nil,
			date_quantity: nil,
			past_index: nil
		}
		
		past_params[:past_value] = @formatted_params & EXISTING_PATTERNS[:past]
		
		# case for yesterday
		if past_params[:past_value] && @formatted_params.length == 1
			calculate_time('days',1,"ago")
		
		# case for string containing last or previous ( Immediate Past)
		elsif  is_immediate_past?(past_params[:past_value])
			# Removing preposition like on, at
			temp_formatted_params = @formatted_params.reject{|item| item == /on|at/i }
			
			# check if the user is inputing a weekeday 
			if is_weekday? temp_formatted_params[1]
				Date.today.beginning_of_week(:temp_formatted_params[1])
			# if its one among year, day, month
			else 
				calculate_time(temp_formatted_params[1],1,"ago")
			end
	
		# case for string containing ago or before etc (non-immediate past)
		elsif !(past_params[:past_value] & ['ago','before']).empty?
			temp_formatted_params =  @formatted_params.reject{|item| item == /on|at|ago|before/i }
						
			# Extracting Values
			past_params[:date_quantity]  = temp_formatted_params[0]
			past_params[:date_type]  = temp_formatted_params[1]
			
			# Calcuate Datetime
			calculate_time(past_params[:date_type],past_params[:date_quantity].to_i,"ago")
		end
	 end
	 
	 def calculate_future_date
		# storing the various parameters
		future_params = {
			future_type: nil,
			future_value: nil,
			date_type: nil,
			date_quantity: nil,
			future_index: nil
		}
		future_params[:future_value] = @formatted_params & EXISTING_PATTERNS[:future]
		
		# case for tomorrow
		if future_params[:future_value] == ["tomorrow"] && @formatted_params.length == 1
			calculate_time('days',1,"from_now")
		
		# Case for immediate future	
		elsif is_immediate_future? @formatted_params
			future_params[:future_type] ='immediate'
			future_params[:date_type]  = @formatted_params[1]
			
			# check if the user is inputing a weekeday 
			# can be exteneded with options like next full moon, next christmas etc
			if is_weekday? @formatted_params[1]
				date_of_next @formatted_params[1]
			# it its one among year, day, month
			else 
				calculate_time(@formatted_params[1],1,"from_now")
			end
			
		# case for string non-immediate future like 'later','in
		elsif !(future_params[:future_value] & ['later','in']).empty?
			future_params[:future_type] = 'future'
			temp_formatted_params =  @formatted_params.reject{|item| item =~ /later|in/i }
	
			# Extracting Values
			future_params[:date_quantity]  = temp_formatted_params[0]
			future_params[:date_type]  = temp_formatted_params[1]
			calculate_time(future_params[:date_type],future_params[:date_quantity].to_i,"from_now")
		end
	 end
	 
	 # reutrns if its a valid day of the week
	 def is_weekday?(day)
		day && (EXISTING_PATTERNS[:days].include? day)
	 end
	 
	 # Return the next specific weekeday. Example: next tuesday
	 def date_of_next(day)
	  date  = Date.parse(day)
	  delta = date > Date.today ? 0 : 7
	  date + delta
	end
	 
	 def is_immediate_future?(data)
		data.include? "next"
	 end
	 
	 def is_immediate_past?(data)
		!(data & ['last', 'previous']).empty?
	 end
	 
	 def calculate_time(type, quantity, tense)
		type = type.pluralize
		quantity.send(type).send(tense)
	 end
	 
 end
end