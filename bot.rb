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
  text.gsub(/(@\w+)/) {|s| client.user(s).name }
  string = ''
  string += text
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
  return tweet.text.gsub(/((https:\/\/t\.co\/\S+))/, '').gsub(/(@\w+)/) {|s| client.user(s).name }.strip
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

  current_filename = "./media/tweets/#{timestamp}.pdf"
  tweets_path = "./media/tweets/*.pdf"

  return if Dir[tweets_path].include?(current_filename)
  company = %w(SpaceX Tesla solarcity boringcompany).sample

  # do nothing if most recent tweet has been formatted already

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
    text "#{tweet.user.name}, et al.", style: :bold, size: 15, align: :left

    move_down 5
    stroke_horizontal_rule
    move_down 10

    column_box([0, cursor], :columns => 2, :width => bounds.width, height: 250) do
      define_grid(:columns => 4, :rows => 12, :gutter => 10)

      title_box = grid([0, 0], [2, 3])

      text_box get_title(tweet, client).upcase, at: [title_box.left, title_box.top], style: :bold, width: title_box.width, height: title_box.height, overflow: :shrink_to_fit, min_font_size: 10, size: 30

      grid(3, 0).bounding_box do
        text "Applicant:"
      end
      grid([3, 1], [3,3]).bounding_box do
        indent(-15) do
          text "#{tweet.user.name}", style: :bold
        end
      end

      grid(4, 0).bounding_box do
        text "Inventors:"
      end
      inventors_string = ''
      inventors(tweet, client, company).each do |inventor|
        inventors_string += "<b>#{inventor.name}</b>, @#{inventor.screen_name} (US); "
      end
      grid([4, 1], [6,3]).bounding_box do
        indent(-15) do
          text inventors_string.chomp('; '), inline_format: true, leading: -3
        end
      end

      grid(6, 0).bounding_box do
        text "Appl. No.:"
      end
      grid([6, 1], [6,3]).bounding_box do
        indent(-15) do
          text "#{tweet.favorite_count}/" +
          "#{tweet.retweet_count}", style: :bold
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
          " #{tweet.user.favourites_count}/#{tweet.user.friends_count}", style: :bold_italic
        end

        grid(1,2).bounding_box do
          text "(#{time.strftime('%Y.%m')})"
        end

        grid(2,0).bounding_box do
          text "U.S. Cl.", style: :bold
        end

        grid([3,0], [3,1]).bounding_box do
          text SecureRandom.hex(2).upcase +
          " 00/#{tweet.user.statuses_count}", style: :bold_italic
        end

        grid(3,2).bounding_box do
          text "(#{account_created.strftime('%Y.%m')})"
        end
      end

      pad_bottom(45) { text "ABSTRACT", style: :bold, align: :center }

      text "#{abstract(tweet, client)}", align: :justify
      # put this into a text_box that will truncate text
    end #column_box

    labels = abstract(tweet, client).gsub(/[\.!?,]/, '').split.map do |label|
      next if label.length < 2
      label.gsub(/(@\w+)/) {|s| client.user(s).name } if label.start_with?('@')
      label.capitalize
    end.compact.uniq

    samples = %W(Elon Grimes 420 Emeralds)

    (4 - labels.length).times do
      labels << samples.delete(samples.sample)
    end

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

  image = Magick::Image.read(current_filename)
  image[0].write(current_filename.sub(".pdf", "") + ".png")

  png_path = "./media/tweets/#{timestamp}.png"

  png_file = File.new png_path

  client.update_with_media "new product from #{companies.sample}:", png_file, in_reply_to_status: tweet

  Dir[tweets_path].reject{ |file_name| file_name.include?(timestamp) }.each do |pdf_path|
    File.delete(pdf_path)
  end

  File.delete(png_path)

end #get_tweets

get_tweets
