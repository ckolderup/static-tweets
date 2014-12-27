require 'open-uri'
require 'storify'
load './static_tweets.rb'

class Tweets < Thor
  include StaticTweets

  desc "from_file FILE",
    "make tweet backup from a file of tweet URLs"
  def from_file(filename)
    ids = StaticTweets::ids_from_tweet_urls(File.readlines(filename).join("\n"))
    StaticTweets::run_all(ids, filename)
  end

  desc "from_url URL",
    "make tweet backup scraping all tweets mentioned in the supplied URL"
  def from_url(url)
    document = open(url){ |io| io.read }
    ids = StaticTweets::ids_from_tweet_urls(document)
    StaticTweets::run_all(ids, File.basename(URI.parse(url).path))
  end

  desc "from_storify URL",
    "make tweet backup from storify story"
  def from_storify(url)
    results = url.scan(/https?:\/\/storify.com\/(.+)\/(.+)/)

    ids = []
    if results.any?
      user, slug = results.first

      client = Storify::Client.new do |config|
        config.api_key  = ENV['STORIFY_API_KEY']
      end

      story = client.story(slug, user)
      ids = story.elements
          .map { |e| e.permalink }
          .map { |url| StaticTweets::ids_from_tweet_urls(url) }
          .flatten
          .uniq
    end

    StaticTweets::run_all(ids, slug)
  end
end
