#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'

require 'twitter'
require 'json'
require 'dotenv/load'
require 'prawn'

Prawn::Font::AFM.hide_m17n_warning = true

def get_tweets(from: 'elonmusk', number: 1)
  # client = Twitter::REST::Client.new do |config|
  #   config.consumer_key        = ENV["CONSUMER_KEY"]
  #   config.consumer_secret     = ENV["CONSUMER_SECRET"]
  #   config.access_token        = ENV["ACCESS_TOKEN"]
  #   config.access_token_secret = ENV["ACCESS_SECRET"]
  # end

  time = Time.now.getutc
  # replace with tweet timestamp
  timestamp = time.strftime('%Y%m%d%H%M%S%L')

  # client.search("from:#{from}", result_type: "recent").take(number).each do |tweet|
    # next if tweet.reply? or tweet.retweet?
    # figure out how to do threads -- first tweet is title, subsequent ones are abstract?
    Prawn::Document.generate("media/tweets/#{timestamp}.pdf") do
      font 'Times-Roman'
      text "United States\nPatent Application Publication", style: :bold, size: 20, align: :left
      text "@elonmusk, et al.", style: :bold, size: 15, align: :left
      # replace with tweet.user.screen_name
      stroke_horizontal_rule
      move_down 10
      stroke_axis
      column_box([0, cursor], :columns => 2, :width => bounds.width, height: 250) do
        # text tweet.text
        pad_bottom(5) { text '@annerajb No, it’s the first or boost stage, analogous to, but much larger than Falcon 9'.upcase, style: :bold }
        pad_bottom(5) { text "Applicant: <b>@elonmusk</b>", inline_format: :true }
        #  replace with tweet.user.screen_name
        end
      float do
        bounding_box([350, 685], width: 164, height: 25) do
          # stroke_bounds
          text "Pub. No.: <b><font size='12'>US #{timestamp[0..3]}/#{rand(1_000_000).to_s} A1</font></b>", style: :bold, size: 10, align: :left, inline_format: true
          text "Pub. Date: <b><font size='12'>#{time.strftime('%b. %e, %Y')}</font></b>", style: :bold, size: 10, align: :left, inline_format: true
        end
      end
    end
  # end
end

get_tweets
