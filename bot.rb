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

require 'rmagick'

require 'date'

require_relative 'fonts'

def reply_to_self?(tweet)
  tweet.reply? and tweet.in_reply_to_user_id == tweet.user.id
end

def abstract(tweet, client)
  text = tweet.full_text.gsub(/((https:\/\/t\.co\/\S+))/, '').strip
  text += !!(text =~ /[\.!?]\z/) ? ' ' : '. '
  string = ''
  string += text.gsub(/@(\w+)/) { |s| tweet.user_mentions.find { |u| u.screen_name == $1 }&.name }
  if reply_to_self?(tweet)
    string.prepend abstract(client.status(tweet.in_reply_to_status_id), client)
  end
  return string
end

def inventors(tweet, client, company)
  array = []
  array << tweet.user
  array << client.user(id: '1065049791829237765')
  unless tweet.user_mentions.first.nil?
    array << tweet.user_mentions.first
  end
  array.compact.uniq
  if array.length < 3
    array << client.user(company)
  end
  return array
end

def get_title(tweet, client)
  return get_title(client.status(tweet.in_reply_to_status_id), client) if reply_to_self? tweet
  return tweet.text.gsub(/((https:\/\/t\.co\/\S+))/, '').gsub(/@(\w+)/) { |s| tweet.user_mentions.find { |u| u.screen_name == $1 }&.name }.strip
end

def get_company(tweet)
  mentions = tweet.user_mentions.collect(&:screen_name)
  companies = %w(SpaceX Tesla solarcity boringcompany)
  ( mentions & companies ).first or companies.sample
end

def tweet_too_old?(tweet)
  (Time.now.utc - tweet.created_at) / 60 > 10
end

def get_tweets(from: 'elonmusk', number: 1)
  client = Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV["CONSUMER_KEY"]
    config.consumer_secret     = ENV["CONSUMER_SECRET"]
    config.access_token        = ENV["ACCESS_TOKEN"]
    config.access_token_secret = ENV["ACCESS_SECRET"]
  end

  tweet = client.search("from:#{from}", result_type: "recent").take(1).last

  time = tweet.created_at
  timestamp = time.strftime('%Y%m%d%H%M%S%L')

  abstracted_tweet = abstract(tweet, client)

  return if tweet.retweet? or tweet_too_old?(tweet)
  # do nothing if most recent tweet is too old (> 10 minutes)

  company = get_company(tweet)

  account_created = tweet.user.created_at

  Prawn::Document.generate("media/tweets/#{timestamp}.pdf") do
    float do
      canvas do
        fill_color "FFFFFF"
        fill_rectangle [bounds.left, bounds.top], bounds.right, bounds.top
      end
    end
    fill_color "000000"
    add_fonts

    upc = "#{tweet.id}"

    barcode = Barby::Code39.new upc
    outputter = Barby::PrawnOutputter.new(barcode)
    barcode.annotate_pdf(self, height: 20, x: (bounds.width - outputter.width), y: bounds.top )

    text_box upc.gsub('/', ''), at: [(bounds.width - outputter.width), bounds.top], size: 10, align: :center

    text_box 'Pub. No.: ', at: [300, 690], style: :bold, size: 12, align: :left, width: (bounds.width - 300)
    text_box upc, at: [300, 690], style: :bold, size: 15, align: :right, width: (bounds.width - 300)
    text_box 'Pub. Date: ', at: [300, 675], style: :bold, size: 12, align: :left, width: (bounds.width - 300)
    text_box time.strftime('%b. %e, %Y'), at: [300, 675], style: :bold, size: 15, align: :right, width: (bounds.width - 300)

    text "United States\nPatent Application Publication", style: :bold, size: 20, align: :left
    text "#{tweet.user.name.split.last} et al.", style: :bold, size: 15, align: :left

    move_down 5
    stroke_horizontal_rule
    move_down 10

    column_box([0, cursor], :columns => 2, :width => bounds.width, height: 250) do
      ###
      # Grid
      ###
      define_grid(:columns => 4, :rows => 12, :gutter => 10)

      title_box = grid([0, 0], [1, 3])

      text_box get_title(tweet, client).upcase, at: [title_box.left, title_box.top], style: :bold, width: title_box.width, height: title_box.height, overflow: :shrink_to_fit, min_font_size: 10, size: 14, leading: -2

      grid(2, 0).bounding_box do
        text "Applicant:"
      end
      grid([2, 1], [2, 3]).bounding_box do
        indent(-15) do
          text "#{tweet.user.name}", style: :bold
        end
      end

      grid(3, 0).bounding_box do
        text "Inventors:"
      end
      inventors_string = ''
      inventors(tweet, client, company).each do |inventor|
        inventors_string += "<b>#{inventor.name}</b>, @#{inventor.screen_name};\n"
      end
      grid([3, 1], [5,3]).bounding_box do
        indent(-15) do
          text inventors_string.chomp(";\n"), inline_format: true, leading: -1
        end
      end

      grid(5, 0).bounding_box do
        text "Appl. No.:"
      end
      grid([5, 1], [5, 3]).bounding_box do
        indent(-15) do
          text "#{tweet.favorite_count}/" +
          "#{tweet.retweet_count}", style: :bold
        end
      end

      grid(6, 0).bounding_box do
        text "Filed:"
      end
      grid([6, 1], [6,3]).bounding_box do
        indent(-15) do
          text "#{account_created.strftime('%b.%e, %Y')}", style: :bold
        end
      end

      grid([7, 1], [7,3]).bounding_box do
        text "Publication Classification", style: :bold
      end

      grid([8, 0], [11,3]).bounding_box do
        ###
        # Grid
        ###
        define_grid(:columns => 4, :rows => 5, :gutter => 1)

        grid(0,0).bounding_box do
          text "Int. Cl.", style: :bold
        end

        grid([1,0], [1,1]).bounding_box do
          text SecureRandom.hex(2).upcase +
          "  #{tweet.user.favourites_count}/#{tweet.user.friends_count}", style: :bold_italic
        end

        grid(1,2).bounding_box do
          text "(#{time.strftime('%Y.%m')})"
        end

        grid(2,0).bounding_box do
          text "U.S. Cl.", style: :bold
        end

        grid([3,0], [4,1]).bounding_box do
          text SecureRandom.hex(2).upcase +
          "  00/#{tweet.user.statuses_count}", style: :bold_italic
          text SecureRandom.hex(2).upcase +
          "  00/#{tweet.user.favorites_count}", style: :bold_italic
        end

        grid([3,2], [4,2]).bounding_box do
          text "(#{account_created.strftime('%Y.%m')})"
          text "(#{account_created.strftime('%Y.%m')})"
        end
        ###
        # Grid
        ###
      end
      ###
      # Grid
      ###

      pad_bottom(30) { text "ABSTRACT", style: :bold, align: :center }

      text_box abstracted_tweet, at: [275, cursor], width: bounds.width, height: cursor, align: :justify, overflow: :shrink_to_fit, min_font_size: 10
    end #column_box

    labels = abstracted_tweet.gsub(/[\.!?,]/, '').split.map do |label|
      next if label.length < 4
      label.gsub(/$@(\w+)/) { |s| tweet.user_mentions.find { |u| u.screen_name == $1 }&.name }
      label.upcase
    end.compact.uniq

    labels << %W(ELON GRIMES 420 EMERALDS).sample(4 - labels.length) if labels.length < 4

    bounding_box([0, cursor], width: bounds.width, height: cursor) do
      image Dir["./media/diagrams/*.png"].sample, fit: [bounds.width, bounds.height], vposition: :top, position: :center

      font 'Arial' do
        [[90, 282], [200, 240], [275, 115], [415, 95]].each do |position|
          fill_color "FFFFFF"
          fill_rectangle position, 100, 30
          fill_color "000000"

          text_box labels.delete(labels.sample), at: position, height: 30, width: 100, overflow: :shrink_to_fit, min_font_size: 8, size: 9, align: :center, valign: :top
        end

        text_box 'FIG. 1', at: [0, 20], size: 12, align: :center, width: bounds.width, style: :bold
      end
    end #bounding_box for diagram

  end #generate PDF

  current_filename = "./media/tweets/#{timestamp}.pdf"
  tweets_path = "./media/tweets/*.pdf"

  image = Magick::Image.read(current_filename)
  image[0].write(current_filename.sub(".pdf", "") + ".png")

  png_path = "./media/tweets/#{timestamp}.png"

  png_file = File.new png_path

  client.update_with_media "new patent application from @#{tweet.user.screen_name} and @#{company}:", png_file, in_reply_to_status: tweet if ENV["ENVIRONMENT"] == 'production'

  Dir[tweets_path].reject{ |file_name| file_name.include?(timestamp) }.each do |pdf_path|
    File.delete(pdf_path)
  end

  File.delete(png_path)

end #get_tweets

get_tweets
