require 'csv' 
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

#formats phone numbers to remove all non-numbers and not include 
#numbers >10 starting with a number other than 1 or <10.
def clean_phone_numbers(phone_number)
  phone_number.gsub!(/[\D]/,'').to_s #replaces non-numbers with empty space

 if phone_number.length == 10
  phone_number
 elsif  phone_number.length == 11 && phone_number[0] == "1"
  phone_number[1..10]
 else
  "Bad number!"
 end
end

#returns a hash with times as the
#key and the number of occurences
def time_targets(regdate, hash)
  
  date = DateTime._strptime(regdate, '%m/%d/%y %H:%M')
  date.each do |key, value|
    if key == :hour
    hash[value] += 1
    end
  end
  hash
end

#returns a hash with days of the week as the key
#and the number of occurences as the value
def day_of_week(regdate, array)
  day = Date.strptime(regdate, '%m/%d/%y %H:%M')
  day = day.strftime("%A")
  array.push(day)
  array.tally
end


#zipcodes lengths are formatted to 5 numbers
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

#gets legislators by requesting from civic info api
#using: zipcode, levels, roles
def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators = legislators.officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

#saves each attendees thank you letter in a 
#specified file located in the output directory
def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end
  
puts 'EventManager initialized.'

#reads csv file
contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

#creates file object  from erb file
template_letter = File.read('form_letter.erb')

#create erb template from the form_letter.erb template file
erb_template = ERB.new template_letter

times =  Hash.new(0)
register_days = Hash.new(0)
days = Array.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  
  clean_phone_numbers(row[:homephone])
  
  register_days = day_of_week(row[:regdate], days)
  
  times = time_targets(row[:regdate],times)

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  
  save_thank_you_letter(id, form_letter)

end