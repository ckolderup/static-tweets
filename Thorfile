require 'open-uri'
require 'storify'
require 'dotenv'
load './static_tweets.rb'


class Tweets < Thor
  include StaticTweets
  Dotenv.load

  class_option :force, :type => :boolean, default: false

  desc "from_user USERNAME",
    "make tweet backup from last N tweets by user USERNAME"
  method_option :count, {type: :numeric, default: 200,
    desc: "The number of tweets to fetch(max/default: 200)"}
  def from_user(username)
    StaticTweets::download_user_timeline(username, options)
  end

  desc "from_favs USERNAME",
    "make tweet backup from last N tweets faved by user USERNAME"
  method_option :count, {type: :numeric, default: 100,
    desc: "The number of tweets to fetch(max/default: 100)"}
  def from_favs(username)
    StaticTweets::download_user_favorites(username, options)
  end

  desc "from_search QUERY",
    "make tweet backup from last N tweets matching Twitter search QUERY"
  method_option :count, {type: :numeric, default: 100,
    desc: "The number of tweets to fetch(max/default: 100)"}
  def from_search(query)
    StaticTweets::download_from_search(query, options)
  end

  desc "from_file FILE",
    "make tweet backup from a file of tweet URLs"
  def from_file(filename)
    ids = StaticTweets::ids_from_tweet_urls(File.readlines(filename).join("\n"))
    StaticTweets::download_from_ids(ids, filename, options)
  end

  desc "from_url URL",
    "make tweet backup scraping all tweets mentioned in the supplied URL"
  def from_url(url)
    ids = StaticTweets::ids_from_tweet_urls(open(url){ |io| io.read })
    StaticTweets::download_from_ids(ids, File.basename(URI.parse(url).path), options)
  end

  desc "from_storify URL",
    "make tweet backup from storify story"
  def from_storify(storify_url)
    results = storify_url.scan(/https?:\/\/storify.com\/(.+)\/(.+)/)

    if results.any?
      user, slug = results.first

      client = Storify::Client.new { |c| c.api_key  = ENV['STORIFY_API_KEY'] }
      story = client.story(slug, user)
      if story.elements.any?
        ids = story.elements
            .map { |e| e.permalink }
            .map { |tweet_url| StaticTweets::ids_from_tweet_urls(tweet_url) }
            .flatten.compact.uniq
      end
    end

    StaticTweets::download_from_ids(ids || [], slug, options)
  end
end
