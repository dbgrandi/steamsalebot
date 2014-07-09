#!/usr/bin/env ruby

require 'claide'
require 'nokogiri'
require 'open-uri'

class Game
  attr_accessor :steam_url
  attr_accessor :original_price
  attr_accessor :current_price
  attr_accessor :sale_percent
  attr_accessor :name
  attr_accessor :image_url
  
  def hash
    steam_url.hash
  end

  def eql?(other)
    self == other
  end
  
  def ==(other)
    self.steam_url == other.steam_url
  end
end

class SteamSaleBot < CLAide::Command
  self.summary = "Check Steam for the current Flash Sale"

  self.arguments = 'CACHE_FILE CONSUMER_KEY CONSUMER_SECRET ACCESS_TOKEN ACCESS_SECRET'

  def initialize(argv)
    @cache_file = argv.shift_argument

    @consumer_key = argv.shift_argument
    @consumer_secret = argv.shift_argument
    
    @access_token = argv.shift_argument
    @access_secret = argv.shift_argument
    
    @games = []
    super
  end

  def validate!
    super
    help! "A cache file is required if you want to get notified of new sale items." unless @cache_file
  end

  def run
    puts "running with #{@cache_file}"
    download_current_games
  end
  
  def cookie
    "birthtime=126259201"
  end
  
  def download_current_games
    doc = Nokogiri::HTML(open("http://store.steampowered.com", "Cookie" => cookie))
    flash_deals = doc.search('.flashdeals_row > .summersale_dailydeal_ctn')
    
    flash_deals.each do |i|
      g = Game.new
      g.steam_url = i.search('a')[0].attr('href')
      g.original_price = i.search('.discount_original_price')[0].content
      g.current_price = i.search('.discount_final_price')[0].content
      g.sale_percent = i.search('.discount_pct')[0].content
      @games << g unless @games.include?(g)
    end
    
    @games.each do |g|
      puts g.steam_url
      if !g.name
        g_doc = Nokogiri::HTML(open(g.steam_url, "Cookie" => cookie))
        g.image_url = g_doc.xpath('//link[@rel="image_src"]')[0]["href"]
        g.name = g_doc.search('.apphub_AppName')[0].content
      end
    end
    
    @games.each do |g|
      puts "\n\nname = #{g.name}"
      puts "image = #{g.image_url}"
      puts "url = #{g.steam_url}"
      puts "original price = #{g.original_price}"
      puts "current price = #{g.current_price}"
      puts "original price = #{g.sale_percent}"
    end
    
  end
end

SteamSaleBot.run(ARGV)
