require 'open-uri'
load './static_tweets.rb'

class Tweets < Thor
  include StaticTweets

  desc "from_file FILE",
    "make tweet backup from a file of tweet URLs"
  def from_file(filename)
    tweet_ids = File.readlines(filename)
        .map { |url| Regexp.new(/\/(\d+)$/).match(url)[1] }
        .compact
        .uniq
    StaticTweets::run_all(tweet_ids, filename)
  end
end
