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

  desc "from_url URL",
    "make tweet backup scraping all tweets mentioned in the supplied URL"
  def from_url(url)
    document = open(url){ |io| io.read }
    ids = document.scan(/https?:\/\/twitter\.com\/(\w+)\/status(es)?\/(\d+)/)
        .map { |x| x.last } # just the matched id
        .compact
        .uniq
    StaticTweets::run_all(ids, File.basename(URI.parse(url).path))
  end
end
