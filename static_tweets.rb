require 'twitter'
require 'open-uri'
require 'erb'
require 'date'

# handles tasks required to write a static tweets document
module StaticTweets
  def self.run_all(tweet_ids, filename)
    abort 'No tweets found in input' if tweet_ids.empty?

    dir_name = setup_tweets_directory(filename)

    tweets = tweets_to_files(tweet_ids, dir_name)

    # reorder tweets in the order they were in the input file
    # (the Twitter API bulk download endpoint doesn't retain order)
    tweets = tweets.group_by(&:id)
                   .values_at(*tweet_ids.map(&:to_i))
                   .flatten(1)
                   .compact

    write_index_html(tweets, dir_name)
  end

  private

  def self.setup_tweets_directory(filename)
    dir_name = File.basename(filename, '.*')
                   .gsub(/[^a-zA-Z0-9]/, '-') + '-tweets'

    begin
      Dir.mkdir(dir_name)
    rescue SystemCallError
      abort "Couldn't create directory #{dir_name}"
    end

    dir_name
  end

  def self.twitter_client
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
      File.open("./#{dir_name}/#{tweet.id}-#{idx}#{extension}", 'w') do |f|
        f << open(url).read
      end
    end
  end

  def self.tweets_to_files(tweet_ids, dir_name)
    tweets = []
    tweet_ids.each_slice(100) do |ids|
      twitter_client.statuses(ids).each do |tweet|
        tweets << tweet
        json = JSON.pretty_generate tweet.attrs
        File.write("./#{dir_name}/#{tweet.id}.json", json)
        download_tweet_images(tweet, dir_name) if tweet.media?
      end
    end
    tweets
  end

  def self.write_index_html(tweets, dir_name)
    File.open("./#{dir_name}/index.html", 'w') do |f|
      f << ERB.new(File.read('./tweets.html.erb')).result(binding)
    end
    FileUtils.cp('tweets.css', "./#{dir_name}/tweets.css")
  end
end
