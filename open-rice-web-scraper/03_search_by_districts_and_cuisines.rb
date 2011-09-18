require 'rubygems'
require 'mechanize'

####################
# helper functions #
####################

# - parse the available dropdown list options
# - returns [[Id_1, DistrictName_1], [Id_2, DistrictName_2] ...]
def get_all_option_values(page, attr_name)
  # use HTML selector to identify the HTML tag elements
  page.search("[name=#{attr_name}]").search("option").map do |opt| 
    option_value = opt.attribute("value").value
    [option_value, opt.text.strip.gsub(/\302\240\302\240/, '')] if option_value && option_value.length > 0
  end.compact
end

# - parse the available checkbox list options
# - returns [[Id_1, CuisineName_1], [Id_2, CuisineName_2] ...]
def get_all_checkbox_values(page, attr_name)
  page.search("input[type=checkbox][name=#{attr_name}]").map do |opt| 
    option_value = opt.attribute("value").value
    [option_value, opt.attribute("title").value] if option_value && option_value.length > 0
  end.compact
end


######################
# main program logic #
######################
agent = Mechanize.new
page = agent.get('http://www.openrice.com/english/restaurant/advancesearch.htm?tc=top2')


# STEP 1: retrieve districts list
districts = get_all_option_values(page,"district_id")
# take away those "ALL" options
districts.reject!{ |district| district[0]  =~ /999$/ }

puts "No. of districts: #{districts.count}"
puts "Districts:        #{districts}"


# STEP 2: retrieve cuisines list
cuisines = get_all_checkbox_values(page, "cuisine_id")
# take away those "ALL" options
cuisines.reject!{ |cuisine| cuisine[0]  =~ /999$/ }

puts "No. of cuisines: #{cuisines.count}"
puts "Cuisines:        #{cuisines}"


# STEP 3: search restaurant by District and Cuisine
districts.each do |district|
  district_count += 1
  district_id = district[0]
  district_name = district[1]  
  puts "Processing: #{district_count}, #{district_name}"
  
  cuisines.each do |cuisine|
    cuisine_id = cuisine[0]
    cuisine_name = cuisine[1]
    
    # submit search query with district Id and cuisine Id
    url = "http://www.openrice.com/english/restaurant/sr1.htm?district_id=#{district_id}&cuisine_id=#{cuisine_id}"

    agent = Mechanize.new
    # page now stores the search result page
    page = agent.get(url)
  end
end