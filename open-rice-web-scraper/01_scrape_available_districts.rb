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
