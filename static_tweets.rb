require 'twitter'
require 'open-uri'
require 'erb'
require 'date'
require 'storify'
require 'dotenv'

Dotenv.load

# handles tasks required to write a static tweets document
module StaticTweets
  def self.run_all(tweet_ids, filename)
    abort 'No tweets found in input' if tweet_ids.empty?

    dir_name = setup_directory(filename)
    FileUtils.cd(dir_name)

    tweets = tweets_to_files(tweet_ids)

    # reorder tweets in the order they were in the input file
    # (the Twitter API bulk download endpoint doesn't retain order)
    tweets = tweets.group_by(&:id)
                   .values_at(*tweet_ids)
                   .flatten(1).compact

    write_index_html(tweets, dir_name.gsub(/-tweets$/, ''))
  end

  def self.ids_from_tweet_urls(string)
    string.scan(%r{https?://twitter.com/(\w+)/status(es)?/(\d+)})
          .map(&:last)
          .map(&:to_i)
          .compact.uniq
  end

  private

  def self.setup_directory(filename)
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

  def self.download_tweet_images(tweet)
    tweet.media.map(&:media_url).each_with_index do |url, idx|
      extension = File.extname(URI.parse(url).path)
      File.open("#{tweet.id}-#{idx}#{extension}", 'w') do |f|
        f << open(url).read
      end
    end
  end

  def self.tweets_to_files(tweet_ids)
    tweets = []
    tweet_ids.each_slice(100) do |ids|
      twitter_client.statuses(ids).each do |tweet|
        tweets << tweet
        json = JSON.pretty_generate tweet.attrs
        File.write("#{tweet.id}.json", json)
        download_tweet_images(tweet) if tweet.media?
      end
    end
    tweets
  end

  # TODO: get script path instead of using `..`
  # until then, this can only be run from the same directory as rb/Thorfile
  def self.write_index_html(tweets, title)
    File.open("index.html", 'w') do |f|
      f << ERB.new(File.read('../tweets.html.erb')).result(binding)
    end
    FileUtils.cp('../tweets.css', "tweets.css")
  end
end
