#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'

require 'twitter'
require 'json'
require 'dotenv/load'
require 'prawn'

require 'faker'

require 'barby'
require 'barby/barcode/code_39'
require 'barby/outputter/prawn_outputter'

Prawn::Font::AFM.hide_m17n_warning = true

def location#(tweet)
  # return tweet.geo if tweet.geo?
  # map this to a city, state, country location

  # return tweet.user.location unless tweet.user.location.nil?
  # map this to a city, state, country location

  Faker::Address.city +
  ', ' +
  Faker::Address.state_abbr +
  " (#{Faker::Address.country_code})"
end

def get_user_location(user)
  user.location
end

def get_tweet_location(tweet)
  tweet.geo
end

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
    # (tweet is part of thread if it's a reply to tweet.user)

    Prawn::Document.generate("media/tweets/#{timestamp}.pdf") do
      font 'Times-Roman'
      stroke_axis

      upc = "US #{timestamp[0..3]}/#{rand(1_000_000).to_s} A1"
      # replace rand with tweet.id

      barcode = Barby::Code39.new upc.gsub '/', ''
      outputter = Barby::PrawnOutputter.new(barcode)
      barcode.annotate_pdf(self, height: 20, x: (bounds.width - outputter.width), y: bounds.top )

      float do
        text_box upc.gsub('/', ''), at: [(bounds.width - outputter.width), bounds.top], size: 10, align: :center
      end

      float do
        text_box 'Pub. No.: ', at: [350, 685], style: :bold, size: 12, align: :left, width: (bounds.width - 350)
        text_box upc, at: [350, 685], style: :bold, size: 15, align: :right, width: (bounds.width - 350)
        text_box 'Pub. Date: ', at: [350, 670], style: :bold, size: 12, align: :left, width: (bounds.width - 350)
        text_box time.strftime('%b. %e, %Y'), at: [350, 670], style: :bold, size: 15, align: :right, width: (bounds.width - 350)
      end #float

      text "United States\nPatent Application Publication", style: :bold, size: 20, align: :left
      text "@elonmusk, et al.", style: :bold, size: 15, align: :left
      # replace with tweet.user.screen_name

      stroke_horizontal_rule
      move_down 10

      column_box([0, cursor], :columns => 2, :width => bounds.width, height: 250) do
        define_grid(:columns => 4, :rows => 12, :gutter => 10)

        grid([0, 0], [2, 3]).bounding_box do
          text (0...280).map { ('a'..'z').to_a[rand(26)] }.join.upcase[0..120], style: :bold
          # replace with tweet.text[0..120]
        end

        grid(3, 0).bounding_box do
          text "Applicant:"
        end
        grid([3, 1], [3,3]).bounding_box do
          indent(-15) do
            text "@elonmusk", style: :bold
          end
          # replace with tweet.user.screen_name
        end

        grid(4, 0).bounding_box do
          text "Inventors:"
        end
        grid([4, 1], [6,3]).bounding_box do
          indent(-15) do
            text "<b>Elon Musk</b>, #{location}; <b>Elon's Patents</b>, #{location}; <b>@annerajb</b>, #{location}", inline_format: true, leading: -3
            # replace with tweet.user.name + tweet or user location and my display name + location and tweet.user_mentions.first.name + their location
          end
        end

        grid(6, 0).bounding_box do
          text "Appl. No.:"
        end
        grid([6, 1], [6,3]).bounding_box do
          indent(-15) do
            text "#{time.strftime('%y')}/#{rand(100_000).to_s}", style: :bold
            # replace with tweet ratio: "#{tweet.favorite_count}/#{tweet.retweet_count}"
          end
        end

        grid(7, 0).bounding_box do
          text "Filed:"
        end
        grid([7, 1], [7,3]).bounding_box do
          indent(-15) do
            text "#{time.strftime('%b. %e, %Y')}", style: :bold
            # replace with tweet.created_at
          end
        end

        grid([8, 1], [8,3]).bounding_box do
          text "Publication Classification", style: :bold
          # replace with tweet.created_at
        end

        grid([9, 0], [11,3]).bounding_box do
          stroke_bounds
          styles = %i[ bold italic bold_italic normal]
          # 5 - tweet.user_mentions.first(2).count lines of randomly-styled letters and numbers
          4.times do
            text "Random Format stuff here\n", style: styles.sample, align: :center
          end
        end


        pad_bottom(45) { text "ABSTRACT", style: :bold, align: :center }

        pad_bottom(10) { text "#{'No, it’s the first or boost stage, analogous to, but much larger than Falcon 9. ' * 5 }", align: :justify}
        # replace with tweet.text, or entire thread if threaded
      end #column_box

      # randomly draw (and label) some diagrams

    end #generate PDF

  # end #client.search
end #get_tweets

get_tweets
