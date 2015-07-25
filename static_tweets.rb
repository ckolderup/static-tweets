require 'twitter'
require 'open-uri'
require 'erb'
require 'date'
require 'storify'
require 'dotenv'

Dotenv.load

SEARCH_DEFAULTS = { count: 100 }
TIMELINE_DEFAULTS = { count: 200 }
FAVORITES_DEFAULTS = { count: 100 }

# handles tasks required to write a static tweets document
module StaticTweets
  def self.download_from_search(query, options)
    page_title = "Tweets matching #{query}"
    safe_query = query.gsub(/[^a-zA-Z0-9]/,'-').squeeze('-').chomp('-').downcase
    dir_name = "#{safe_query}-search-#{Time.now.strftime('%Y%m%d%H%M%S')}"

    download(:search, query, page_title, dir_name, SEARCH_DEFAULTS, options)
  end

  def self.download_user_timeline(username, options)
    page_title = "@#{username}'s Tweets"
    dir_name = "#{username}-tweets-#{Time.now.strftime('%Y%m%d%H%M%S')}"

    download(:user_timeline, username, page_title,
             dir_name, TIMELINE_DEFAULTS, options)
  end

  def self.download_user_favorites(username, options)
    page_title = "@#{username}'s Favorites"
    dir_name = "#{username}-favs-#{Time.now.strftime('%Y%m%d%H%M%S')}"

    download(:favorites, username, page_title, dir_name,
             FAVORITES_DEFAULTS, options)
  end

  def self.download_from_ids(tweet_ids, filename, options)
    tweets = []
    tweet_ids.each_slice(100) do |ids|
      tweets.push(*twitter.statuses(ids))
    end

    page_title = File.basename(filename, '.*')
                   .gsub(/[^a-zA-Z0-9]/, '-')
    dir_name = page_title + '-tweets'
    setup_directory(dir_name, !!options[:force])

    tweets_to_files(tweets, dir_name)

    # reorder tweets in the order they were in the input file
    # (the Twitter API bulk download endpoint doesn't retain order)
    tweets = tweets.group_by(&:id)
                   .values_at(*tweet_ids)
                   .flatten(1).compact

    write_index_html(tweets, page_title, dir_name)
  end

  def self.ids_from_tweet_urls(string)
    string.scan(%r{https?://twitter.com/(\w+)/status(es)?/(\d+)})
          .map(&:last)
          .map(&:to_i)
          .compact.uniq
  end

  private

  def self.download(client_method_sym, param, title, dir_name, defaults, opts)
    #symbolize keys for opts since Thor uses string keys UGH
    opts = Hash[opts.map{ |k, v| [k.to_sym, v] }]
    abort "API max is #{defaults[:count]}" if opts[:count] > defaults[:count]

    tweets = twitter.send(client_method_sym, param, defaults.merge(opts))
                    .take(opts[:count]) # necessary since search returns a dumb
                                        # object that includes Enumerable

    setup_directory(dir_name, !!opts[:force])
    tweets_to_files(tweets, dir_name)
    write_index_html(tweets, title, dir_name)
  end


  def self.setup_directory(dir_name, overwrite_ok)
    begin
      Dir.mkdir(dir_name)
    rescue SystemCallError
      abort "Couldn't create directory #{dir_name}" unless overwrite_ok
    end
  end

  def self.twitter
    Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
    end
  end

  def self.download_tweet_images(tweet, dir_name)
    tweet.media.map(&:media_url).each_with_index do |url, idx|
      extension = File.extname(URI.parse(url).path)
      download_image(url, "#{dir_name}/#{tweet.id}-#{idx}#{extension}")
    end
  end

  def self.download_tweet_avatar(tweet, dir_name)
    url = tweet.user.profile_image_url
    extension = File.extname(URI.parse(url).path)
    download_image(url, "#{dir_name}/#{tweet.user.id}#{extension}")
  end

  def self.download_image(url, filename)
    File.open(filename, 'w') do |f|
      f << open(url).read
    end
  end


  def self.tweets_to_files(tweets, dir_name)
    abort 'No tweets found in input' if tweets.empty?

    tweets.each do |tweet|
      json = JSON.pretty_generate tweet.attrs
      File.write("#{dir_name}/#{tweet.id}.json", json)
      download_tweet_images(tweet, dir_name) if tweet.media?
      download_tweet_avatar(tweet, dir_name)
    end
  end

  def self.write_index_html(tweets, title, dir_name)
    File.open("#{dir_name}/index.html", 'w') do |f|
      f << ERB.new(File.read(
                    File.join(File.dirname(__FILE__), 'tweets.html.erb')
                  )).result(binding)
    end
    FileUtils.cp(File.join(File.dirname(__FILE__), 'tweets.css'),
                 "#{dir_name}/tweets.css")
  end
end
