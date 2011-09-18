# encoding: UTF-8

#
# loading the mechanize library for scraping
# install it if you haven't done it:
#   sudo gem install mechanize
#
require 'mechanize'

agent = Mechanize.new
page = agent.get("http://www.openrice.com/restaurant/sr2.htm?shopid=32108")

#
# use the css selector to identify the address HTML tag element
# specify [2] because the address stays in the third td tag element
#
address_element = page.search("table.addetail tr td div table tr td")[2]

# Special handling of chinese characters
unicode_colon = '英文地址：'
puts address_element.text.match(/(.*)#{unicode_colon}/)[1]