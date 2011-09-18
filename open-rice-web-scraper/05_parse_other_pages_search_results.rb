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
  # use HTML selector to identify the HTML tag elements
  page.search("input[type=checkbox][name=#{attr_name}]").map do |opt| 
    option_value = opt.attribute("value").value
    [option_value, opt.attribute("title").value] if option_value && option_value.length > 0
  end.compact
end

# - parse single search result page
# - go thru every restaurant result page and stores information found
# - returns [[ShopName_1, ShopTel_1, ShopAddress_1, ShopType_1, ShopExpense_1, ShopRating_1, DistrictName, CuisineName],
#            [ShopName_2, ShopTel_2, ShopAddress_2, ...]
#           ]
def parse_single_page_search_result(page, district_name, cuisine_name)
  single_page_rows = []
  
  page.search(".sr1_list").each do |shop|
    shop_name        = shop.search(".restname").children.first.text
    shop_tel         = shop.search(".tel").text
    shop_expenditure = shop.search(".price").text
    shop_address     = shop.search(".add").text
    shop_type        = shop.search(".type").children.text
    shop_rating      = shop.search(".sr1score span").map do |score| score.text end.join('/')

    single_page_rows << [shop_name, shop_tel, shop_address, shop_type, shop_expenditure, shop_rating, district_name, cuisine_name]
  end
  
  single_page_rows
end

# - parse the "no. of result pages" in the HTML
def max_paging_count(page)
  field = page.search('.pagination form div')
  # use regular expression to extract the max. result page value
  field.first.text.match(/Jump to page\(1-(.*)\)/)[1] if field.any?
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
result_rows = []

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
    
    
    # STEP 4: parse first page search results
    result_rows += parse_single_page_search_result(page, district_name, cuisine_name)
    
    
    # STEP 5: parse other pages search results
    page_count = max_paging_count(page)
    if page_count
      (2..page_count.to_i).each do |page_index|
        # submit search query with district Id, cuisine Id and page number
        page = agent.get("#{url}&page=#{page_index}")
        result_rows += parse_single_page_search_result(page, district_name, cuisine_name)
      end
    end
  end
end

puts "No. of restaurants: #{result_rows.count}"
puts "Restaurant:         #{result_rows}"