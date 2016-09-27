#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'colorize'
require 'pry'
# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)

  areas = Hash[*noko.css('#contentwrap h3').map { |h3|
    # the names appear in subtly different formats in each place…
    h3.xpath('following-sibling::ul[1]/li/a').map { |a| [a.text.tidy.gsub('.',''), h3.text.tidy] }
  }.flatten]

  noko.css('table[@summary="Contacts table"] tr').each do |tr|
    tds = tr.css('td')
    name = tds[0].text.tidy
    data = { 
      name: name,
      area: areas[name.gsub('.','')] || raise("No area"),
      party: "Independent",
      email: tds[1].css('a[href*="mailto:"]/@href').text.sub('mailto:',''),
      twitter: tds[2].css('a[href*="twitter"]/@href').text,
      linkedin: tds[3].css('a[href*="linkedin"]/@href').text,
      term: 2012,
      source: url,
    }
    # puts data
    ScraperWiki.save_sqlite([:name, :term], data)
  end

end

scrape_list('http://theoldsite.gov.gg/states_members_contact_details')
