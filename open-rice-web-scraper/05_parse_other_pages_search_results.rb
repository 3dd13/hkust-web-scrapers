# encoding: UTF-8

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
  
  page.search("#restlist table[cellspacing=\"5\"]").each do |shop|
    shop_name        = shop.search(".resttitle").children.first.text.strip
    shop_tel         = shop.search(".listphone").text.strip
    shop_expenditure = shop.search(".listprice").text.strip
    shop_address     = shop.search(".listadd").text.strip
    shop_type        = shop.search(".listdish").children.text.strip
    
    shop_rating_good = shop.search('tr[2]/td[2]/span[1]').text.strip
    shop_rating_bad  = shop.search('tr[2]/td[2]/span[4]').text.strip

    single_page_rows << [shop_name, shop_tel, shop_address, shop_type, shop_expenditure, shop_rating_good, shop_rating_bad, district_name, cuisine_name]
  end
  
  single_page_rows
end

# - parse the "no. of result pages" in the HTML
def max_paging_count(page)
  field = page.search('.pagination form div')
  # use regular expression to extract the max. result page value
  field.first.text.match(/\(1-(.*)\)/)[1] if field.any?
end


######################
# main program logic #
######################
agent = Mechanize.new
page = agent.get('http://www.openrice.com/restaurant/advancesearch.htm?tc=top2')


# STEP 1: retrieve districts list
districts = get_all_option_values(page,"district_id")
# take away those "ALL" options
districts.reject!{ |district| district[0]  =~ /999$/ }

# puts "No. of districts: #{districts.count}"
# puts "Districts:        #{districts}"


# STEP 2: retrieve cuisines list
cuisines = get_all_checkbox_values(page, "cuisine_id")
# take away those "ALL" options
cuisines.reject!{ |cuisine| cuisine[0]  =~ /999$/ }

# puts "No. of cuisines: #{cuisines.count}"
# puts "Cuisines:        #{cuisines}"


# STEP 3: search restaurant by District and Cuisine
result_rows = []

district_count = 0
districts.each do |district|
  district_count += 1
  district_id = district[0]
  district_name = district[1]  
  puts "Processing: #{district_count}, #{district_name}"
  
  cuisines.each do |cuisine|
    cuisine_id = cuisine[0]
    cuisine_name = cuisine[1]
    
    # submit search query with district Id and cuisine Id
    url = "http://www.openrice.com/restaurant/sr1.htm?district_id=#{district_id}&cuisine_id=#{cuisine_id}"

    agent = Mechanize.new
    # page now stores the search result page
    page = agent.get(url)
    
    
    # STEP 4: parse first page search results
    result_rows += parse_single_page_search_result(page, district_name, cuisine_name)
    
    
    # STEP 5: parse other pages search results
    page_count = max_paging_count(page)
    
    puts "page_count: #{page_count}"
    if page_count
      (2..page_count.to_i).each do |page_index|
        # submit search query with district Id, cuisine Id and page number
        page = agent.get("#{url}&page=#{page_index}")
        single_page_result = parse_single_page_search_result(page, district_name, cuisine_name)
        
        puts "other page result: Page #{page_index}, #{single_page_result}"
        result_rows += single_page_result
      end
    end
  end
end

puts "No. of restaurants: #{result_rows.count}"
puts "Restaurant:         #{result_rows}"