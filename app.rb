require 'twitter'
require 'open-uri'
require 'erb'
require 'date'

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
  config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
  config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
end

def tweet_ids_from_urls_file(filename)
  File.readlines(filename)
      .map { |url| Regexp.new('\/(\d+)$').match(url)[1] }
      .compact
end

abort 'No input file' unless ARGV[0]

tweet_ids = tweet_ids_from_urls_file(ARGV[0])
abort 'No tweets found in input file' if tweet_ids.empty?

dir_name = File.basename(ARGV[0], '.*').gsub(/[^a-zA-Z0-9]/, '-') + '-tweets'

begin
  Dir.mkdir(dir_name)
rescue SystemCallError
  abort "Couldn't create directory #{dir_name}"
end

tweets = []
nil_responses = tweet_ids
tweet_ids.each_slice(100) do |ids|
  client.statuses(ids).each do |tweet|
    tweets << tweet
    json = JSON.pretty_generate tweet.attrs
    File.write("./#{dir_name}/#{tweet.id}.json", json)
    next unless tweet.media?

    tweet.media.map(&:media_url).each_with_index do |url, idx|
      extension = File.extname(URI.parse(url).path)
      File.open("./#{dir_name}/#{tweet.id}-#{idx}#{extension}", 'w') do |f|
        f << open(url).read
      end
    end
  end
end

tweets = tweets.group_by(&:id).values_at(*tweet_ids.map(&:to_i)).flatten(1).compact

File.open("./#{dir_name}/index.html", 'w') do |f|
  f << ERB.new(File.read('./tweets.html.erb')).result(binding)
end
FileUtils.cp('tweets.css', "./#{dir_name}/tweets.css")
