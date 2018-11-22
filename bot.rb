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

require 'date'

require_relative 'fonts'

TWEET = {
  :created_at=>"Wed Nov 21 15:57:52 +0000 2018",
  :id=>1065273096813203458,
  :id_str=>"1065273096813203458",
  :text=>"@FredericLambert @speceye @Tesla Good idea",
  :truncated=>false,
  :entities=>{
    :hashtags=>[],
    :symbols=>[],
    :user_mentions=>[
      {:screen_name=>"FredericLambert",
        :name=>"Fred Lambert🍣🍣🍣🍣🍣",
        :id=>38253449,
        :id_str=>"38253449",
        :indices=>[0, 16]},
      {:screen_name=>"speceye",
        :name=>"John Henahan",
        :id=>23550675,
        :id_str=>"23550675",
        :indices=>[17, 25]},
      {:screen_name=>"Tesla",
        :name=>"Tesla",
        :id=>13298072,
        :id_str=>"13298072",
        :indices=>[26, 32]}],
    :urls=>[]},
    :metadata=>
      {:iso_language_code=>"en",
        :result_type=>"recent"},
    :source=>"<a href=\"http://twitter.com/download/iphone\" rel=\"nofollow\">Twitter for iPhone</a>",
    :in_reply_to_status_id=>1065271507188965377,
    :in_reply_to_status_id_str=>"1065271507188965377",
    :in_reply_to_user_id=>38253449,
    :in_reply_to_user_id_str=>"38253449",
    :in_reply_to_screen_name=>"FredericLambert",
    :user=>{
      :id=>44196397,
      :id_str=>"44196397",
      :name=>"Elon Musk",
      :screen_name=>"elonmusk",
      :location=>"",
      :description=>"",
      :url=>nil,
      :entities=>
        {:description=>
          {:urls=>[]}
        },
      :protected=>false,
      :followers_count=>23471870,
      :friends_count=>75,
      :listed_count=>47443,
      :created_at=>"Tue Jun 02 20:12:29 +0000 2009",
      :favourites_count=>1836,
      :utc_offset=>nil,
      :time_zone=>nil,
      :geo_enabled=>false,
      :verified=>true,
      :statuses_count=>5995,
      :lang=>"en",
      :contributors_enabled=>false,
      :is_translator=>false,
      :is_translation_enabled=>false,
      :profile_background_color=>"C0DEED",
      :profile_background_image_url=>"http://abs.twimg.com/images/themes/theme1/bg.png",
      :profile_background_image_url_https=>"https://abs.twimg.com/images/themes/theme1/bg.png",
      :profile_background_tile=>false,
      :profile_image_url=>"http://pbs.twimg.com/profile_images/972170159614906369/0o9cdCOp_normal.jpg",
      :profile_image_url_https=>"https://pbs.twimg.com/profile_images/972170159614906369/0o9cdCOp_normal.jpg",
      :profile_banner_url=>"https://pbs.twimg.com/profile_banners/44196397/1354486475",
      :profile_link_color=>"0084B4",
      :profile_sidebar_border_color=>"C0DEED",
      :profile_sidebar_fill_color=>"DDEEF6",
      :profile_text_color=>"333333",
      :profile_use_background_image=>true,
      :has_extended_profile=>true,
      :default_profile=>false,
      :default_profile_image=>false,
      :following=>false,
      :follow_request_sent=>false,
      :notifications=>false,
      :translator_type=>"none"},
    :geo=>nil,
    :coordinates=>nil,
    :place=>nil,
    :contributors=>nil,
    :is_quote_status=>false,
    :retweet_count=>21,
    :favorite_count=>458,
    :favorited=>false,
    :retweeted=>false,
    :lang=>"en"}

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

  # APP_USER = client.user(id: '1065049791829237765')

  time = DateTime.parse TWEET[:created_at]
  timestamp = time.strftime('%Y%m%d%H%M%S%L')

  account_created = DateTime.parse TWEET[:user][:created_at]

  # tweet = client.search("from:#{from}", result_type: "recent").take(3).last
  # puts tweet.to_h
  # client.search("from:#{from}", result_type: "recent").take(number).each do |tweet|

    # next if tweet.reply? or tweet.retweet?
    # figure out how to do threads -- first tweet is title, subsequent ones are abstract?
    # (tweet is part of thread if it's a reply to tweet.user)

    Prawn::Document.generate("media/tweets/#{timestamp}.pdf") do
      add_fonts

      upc = "#{TWEET[:id_str]}"

      barcode = Barby::Code39.new upc
      outputter = Barby::PrawnOutputter.new(barcode)
      barcode.annotate_pdf(self, height: 20, x: (bounds.width - outputter.width), y: bounds.top )

      float do
        text_box upc.gsub('/', ''), at: [(bounds.width - outputter.width), bounds.top], size: 10, align: :center
      end

      float do
        text_box 'Pub. No.: ', at: [300, 690], style: :bold, size: 12, align: :left, width: (bounds.width - 300)
        text_box upc, at: [300, 690], style: :bold, size: 15, align: :right, width: (bounds.width - 300)
        text_box 'Pub. Date: ', at: [300, 675], style: :bold, size: 12, align: :left, width: (bounds.width - 300)
        text_box time.strftime('%b. %e, %Y'), at: [300, 675], style: :bold, size: 15, align: :right, width: (bounds.width - 300)
      end #float

      text "United States\nPatent Application Publication", style: :bold, size: 20, align: :left
      text "@#{TWEET[:user][:screen_name]}, et al.", style: :bold, size: 15, align: :left

      move_down 5
      stroke_horizontal_rule
      move_down 10

      column_box([0, cursor], :columns => 2, :width => bounds.width, height: 250) do
        define_grid(:columns => 4, :rows => 12, :gutter => 10)

        title_box = grid([0, 0], [2, 3])

        text_box TWEET[:text].gsub(/(@\S+)/, '').upcase, at: [title_box.left, title_box.top], style: :bold, width: title_box.width, height: title_box.height, overflow: :shrink_to_fit, min_font_size: 10, size: 30

        grid(3, 0).bounding_box do
          text "Applicant:"
        end
        grid([3, 1], [3,3]).bounding_box do
          indent(-15) do
            text "@#{TWEET[:user][:screen_name]}", style: :bold
          end
        end

        grid(4, 0).bounding_box do
          text "Inventors:"
        end
        grid([4, 1], [6,3]).bounding_box do
          indent(-15) do
            text "<b>#{TWEET[:user][:name]}</b>, #{location}; " +
            "<b>Elon's Patents</b>, #{location}; " +
            "<b>#{TWEET[:entities][:user_mentions].first[:name]}</b>, #{location}", inline_format: true, leading: -3
            # replace hardcoded 'Elon's Patents' with APP_USER.name
          end
        end

        grid(6, 0).bounding_box do
          text "Appl. No.:"
        end
        grid([6, 1], [6,3]).bounding_box do
          indent(-15) do
            text "#{TWEET[:favorite_count]}/" +
            "#{TWEET[:retweet_count]}", style: :bold
          end
        end

        grid(7, 0).bounding_box do
          text "Filed:"
        end
        grid([7, 1], [7,3]).bounding_box do
          indent(-15) do
            text "#{account_created.strftime('%b.%e, %Y')}", style: :bold
          end
        end

        grid([8, 1], [8,3]).bounding_box do
          text "Publication Classification", style: :bold
        end

        grid([9, 0], [11,3]).bounding_box do
          define_grid(:columns => 4, :rows => 4, :gutter => 1)

          grid(0,0).bounding_box do
            text "Int. Cl.", style: :bold
          end

          grid([1,0], [1,1]).bounding_box do
            text SecureRandom.hex(2).upcase +
            " #{TWEET[:user][:favourites_count]}/#{TWEET[:user][:friends_count]}", style: :bold_italic
          end

          grid(1,2).bounding_box do
            text "(#{time.strftime('%Y.%m')})"
          end

          grid(2,0).bounding_box do
            text "U.S. Cl.", style: :bold
          end

          grid([3,0], [3,1]).bounding_box do
            text SecureRandom.hex(2).upcase +
            " 00/#{TWEET[:user][:statuses_count]}", style: :bold_italic
          end

          grid(3,2).bounding_box do
            text "(#{account_created.strftime('%Y.%m')})"
          end
        end

        pad_bottom(45) { text "ABSTRACT", style: :bold, align: :center }

        text "#{Faker::Lorem.paragraph(5)}", align: :justify
        # replace with tweet.text, or entire thread if threaded
        # put this into a text_box that will truncate text
      end #column_box

      labels = TWEET[:text].split.map(&:capitalize).reject! { |e| e[0] == '@' }
      labels += %W(Elon Musk) if labels.length <= 2

      bounding_box([0, cursor], width: bounds.width, height: cursor) do
        stroke_axis

        stroke do
          rounded_rectangle [400, 350], 100, 200, 20
          curve [400, 250], [200, 300], :bounds => [[200, 200], [250, 250]]
          curve [450, 150], [150, 75], :bounds => [[300, 150], [350, 200]]
          curve [100, 125], [150, 250], :bounds => [[100, 200], [150, 250]]
        end

        bounding_box([100, 350], :width => 100, height: 100) do
          text labels.delete(labels.sample), valign: :center, align: :center
          transparent(0.5) { stroke_bounds }
        end

        stroke_polygon [50, 100], [100, 125], [150, 100],
                       [150, 50], [100, 25], [50, 50]
        text_box labels.delete(labels.sample), at: [50, 75], width: 100, align: :center

        text_box labels.delete(labels.sample) + "\n" +
        labels.delete(labels.sample), at: [400, 250], width: 100, align: :center
      end #bounding_box for diagram

    end #generate PDF

  # end #client.search
end #get_tweets

get_tweets
