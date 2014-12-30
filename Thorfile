require 'open-uri'
require 'storify'
require 'dotenv'
load './static_tweets.rb'


class Tweets < Thor
  include StaticTweets
  Dotenv.load

  desc "from_user USERNAME",
    "make tweet backup from last N tweets by user USERNAME"
  def from_user(username)
    # TODO
  end

  desc "user_faved USERNAME",
    "make tweet backup from last N tweets faved by user USERNAME"
  def user_faved(username)
    # TODO
  end

  desc "from_search QUERY",
    "make tweet backup from last N tweets matching Twitter search QUERY"
  def from_user(username)
    # TODO
  end

  desc "from_file FILE",
    "make tweet backup from a file of tweet URLs"
  def from_file(filename)
    ids = StaticTweets::ids_from_tweet_urls(File.readlines(filename).join("\n"))
    StaticTweets::run_all(ids, filename)
  end

  desc "from_url URL",
    "make tweet backup scraping all tweets mentioned in the supplied URL"
  def from_url(url)
    ids = StaticTweets::ids_from_tweet_urls(open(url){ |io| io.read })
    StaticTweets::run_all(ids, File.basename(URI.parse(url).path))
  end

  desc "from_storify URL",
    "make tweet backup from storify story"
  def from_storify(url)
    results = url.scan(/https?:\/\/storify.com\/(.+)\/(.+)/)

    if results.any?
      user, slug = results.first

      client = Storify::Client.new { |c| c.api_key  = ENV['STORIFY_API_KEY'] }
      story = client.story(slug, user)
      if story.elements.any?
        ids = story.elements
            .map { |e| e.permalink }
            .map { |url| StaticTweets::ids_from_tweet_urls(url) }
            .flatten.compact.uniq
      end
    end

    StaticTweets::run_all(ids || [], slug)
  end
end
