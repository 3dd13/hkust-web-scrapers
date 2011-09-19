# encoding: UTF-8

require 'rubygems'
require 'mechanize'
require 'csv'

####################
# helper functions #
####################

UFOOD_URL = "http://www.ufood.com.hk"

# - parse detail page
def parse_single_page(page)
  single_page_rows = []
  
  shop_name = page.search("div.rest_details_name").children.first.text.strip
  detail_rows = page.search("div.rest_main_details_1 tr")
  first_row = detail_rows[0].search("td")[1].children
  district = first_row[0].text.strip if first_row[0]
  area = first_row[1].text.strip if first_row[1]
  subarea = first_row[2].text.strip if first_row[2]
  address = first_row[3].text.strip if first_row[3]
  
  telephone = detail_rows[1].search("td")[1].text.strip
  price_range = detail_rows[3].search("td")[1].text.strip
  
  single_page_rows << [shop_name, district, area, subarea, address, telephone, price_range]
  
  single_page_rows
end

# - parse single search result page
def parse_search_result_page(page, agent)
  result_page_rows = []

  page.search(".rest_title a").each do |result_row|
    detail_page_url = result_row.attribute("href").value
    result_page_rows += parse_single_page(agent.get(UFOOD_URL + detail_page_url))
  end
  
  result_page_rows
end

# - parse the "no. of result pages" in the HTML
def max_paging_count(page)
  numbers = page.search(".pagination li").map(&:text).map(&:to_i)
  numbers.max
end

# - ufood website is not very stable, therefore the program stores file after parsing each page
def store_csv_file(results, page_index)
  CSV.open("export/ufood_export_#{page_index}.csv", 'w') {|csv|
    results.each do |row|
      csv << row
    end
  }
end


######################
# main program logic #
######################
SEARCH_URL = "http://www.ufood.com.hk/restaurant/search/result.htm?avgSpendingId=&cuisineTypeId=&distIds=1%2C%202%2C%203%2C%204%2C%205%2C%206%2C%207%2C%208%2C%209%2C%2010%2C%2011%2C%2012%2C%2013%2C%2014%2C%2015%2C%2016%2C%2017%2C%2018%2C%2019%2C%2020%2C%2021%2C%2022%2C%2023%2C%2024%2C%2025%2C%2026%2C%2027%2C%2028%2C%2029%2C%2030%2C%2031%2C%2032%2C%2033%2C%2034%2C%2035%2C%2036%2C%2037%2C%2038%2C%2039%2C%2040%2C%2041%2C%2042%2C%2043%2C%2044%2C%2045%2C%2046%2C%2047%2C%2048%2C%2049%2C%2050%2C%2051%2C%2052%2C%2053%2C%2054%2C%2055%2C%2056%2C%2057%2C%2058%2C%2059%2C%2060%2C%2061%2C%2062%2C%2063%2C%2064%2C%2065%2C%2066%2C%2067%2C%2068%2C%2069%2C%2070%2C%2071%2C%2072%2C%2073%2C%2074%2C%2075%2C%2076%2C%2077%2C%2078%2C%2079%2C%2080%2C%2081%2C%2082%2C%2083%2C%2084%2C%2085%2C%2086%2C%2087%2C%2088%2C%2089%2C%2090%2C%20102&foodTypeId=&name=&occationId=&restaurantTypeId="

start_time = Time.now

# parse first page and get the max. of result pages
agent = Mechanize.new
first_page = agent.get("#{SEARCH_URL}&currentPage=1")
first_page_results = parse_search_result_page(first_page, agent)
store_csv_file(first_page_results, 1)

page_count = max_paging_count(first_page)
puts "Max. no. of page: #{page_count}"

# parse the remaining pages
(2..page_count).each do |page_index|
  page = agent.get("#{SEARCH_URL}&currentPage=#{page_index}")
  result_rows = parse_search_result_page(page, agent)
  
  store_csv_file(result_rows, page_index)
end

p Time.now - start_time
