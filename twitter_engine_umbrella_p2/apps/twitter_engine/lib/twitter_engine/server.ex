defmodule TwitterEngine.Server do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :server)
  end

  def init(init_arg) do
    create_tables()
    {:ok, init_arg}
  end

  def create_tables() do
    # stores process id {username, process id}
    :ets.new(:ProcessMapping, [:set, :protected, :named_table])
    
    # {username, isLoggedIn(Boolean)}
    :ets.new(:UserState, [:set, :protected, :named_table])

    # {username, password}
    :ets.new(:Users, [:set, :protected, :named_table])
    
    # {username, tweets[], retweet_flag[]}
    :ets.new(:Tweets, [:set, :protected, :named_table])
    
    # {username, followers[]}
    :ets.new(:Followers, [:set, :protected, :named_table])
    
    # {username, tweets[](Tweets of user have subscribed to)}
    # stores username and tweets made by other users to which the user is subscribed to
    :ets.new(:Notifications, [:set, :protected, :named_table])
    
    # {hashtag, tweets[]}
    # stores hashtags and the tweet
    :ets.new(:Hashtags, [:set, :protected, :named_table])
    # {username, tweets[]}
    # stores mentions and the tweet
    :ets.new(:Mentions, [:set, :protected, :named_table])
    # stores tweetId,username,tweet
    :ets.new(:TweetById, [:set, :protected, :named_table])
    :ets.new(:SubscribedTo, [:set, :protected, :named_table])
    
  end

  def handle_call({:show_followers, user}, _from, state) do
    {:reply, :ets.lookup_element(:Followers, user, 2), state}
  end

  def handle_call({:subscribe_user, {username, follower}}, _from, state) do
    if :ets.lookup(:Users, username) != [] do
      if Enum.member?(:ets.lookup_element(:SubscribedTo, follower, 2), username) do
        {:reply, {false, "Already Subscribed"}, state}
      else
        [subscribedList] = :ets.lookup(:SubscribedTo, follower)
        oldsubscriber = elem(subscribedList, 1)
        newsubscriber = [username | oldsubscriber]
        :ets.insert(:SubscribedTo, {follower, newsubscriber})

        [listOfFollowers] = :ets.lookup(:Followers, username)
        oldFollower = elem(listOfFollowers, 1)
        newFollower = [follower | oldFollower]
        :ets.insert(:Followers, {username, newFollower})
        {:reply, {true, "Success"}, state}
      end
    else
      {:reply, {false, "User doesn't exist"}, state}
    end
  end

  def handle_call({:get_tweet_by_id, tweet_id}, _from, state) do
    {:reply, :ets.lookup_element(:TweetById, tweet_id, 3), state}
  end

  # register callback
  def handle_call({:register_user, {username, password}}, _from, state) do
    case :ets.lookup(:Users, username) do
      [_] ->
        {:reply, {false, "User already registered"}, state}

      [] ->
        # initializing the tables with no tweets and no followers
        :ets.insert(:Users, {username, password})
        :ets.insert(:Tweets, {username, [], []})
        :ets.insert(:Followers, {username, []})
        :ets.insert(:UserState, {username, false})
        :ets.insert(:Notifications, {username, []})
        :ets.insert(:SubscribedTo, {username, []})
        {:reply, {true, "Registration successful"}, state}
    end
  end

  def handle_call({:is_logged_in, username}, _from, state) do
    {:reply, :ets.lookup_element(:UserState, username, 2), state}
  end

  def handle_call({:is_user_registered, username}, _from, state) do
    {:reply, :ets.lookup(:Users, username) != [], state}
  end

  def handle_call({:delete, username}, _from, state) do
    if :ets.lookup(:Users, username) != [] do
      :ets.delete(:Users, username)
      {:reply, {true, "User Deleted"}, state}
    else
      {:reply, {false, "No user to delete"}, state}
    end
  end

  def handle_call({:search_tweets_by_hashtag, hashtag}, _from, state) do
    result =
      if :ets.lookup(:Hashtags, hashtag) == [] do
        []
      else
        :ets.lookup_element(:Hashtags, hashtag, 2)
      end

    {:reply, result, state}
  end

  def handle_call({:search_my_mentions, mention}, _from, state) do
    if :ets.lookup(:Mentions, mention) == [] do
      {:reply, "mention not found", state}
    else
      {:reply, :ets.lookup_element(:Mentions, mention, 2), state}
    end
  end

  def handle_call({:tweet, {userid, tweet, flag}}, _from, state) do
    # IO.puts("user - #{userid}, tweet - #{tweet}, flag - #{flag}")
    # check for retweet
    # [listOfOldTweets] = :ets.lookup(:Tweets, userid)
    # oldTweet = elem(listOfOldTweets, 1)
    # newTweet = [tweet | oldTweet]
    {all_registered, messageOrMentions} = process_tweet(tweet)

    if all_registered do
      tweetid = (:ets.tab2list(:TweetById) |> length) + 1
        # if(:ets.first(:TweetById) == :"$end_of_table") do
        #  1
        # else
        #  :ets.last(:TweetById) + 1
        # end
      now = DateTime.utc_now()
      :ets.insert(:TweetById, {tweetid, userid, tweet, now})

      # post_tweet_to_subscribers(tweet, userid, messageOrMentions)
      # :ets.insert(:TweetById, {tweetid, userid, tweet})
      oldTweet = :ets.lookup_element(:Tweets, userid, 2)
      newTweet = [tweet | oldTweet]

      oldFlags = :ets.lookup_element(:Tweets, userid, 3)
      newFlag = [flag | oldFlags]
      :ets.insert(:Tweets, {userid, newTweet, newFlag})

      # subscribers = :ets.lookup_element(:Followers, userid, 2)
      # post_tweet_to_subscribers(tweet, userid, subscribers -- messageOrMentions)
      post_tweet_to_subscribers(tweetid, messageOrMentions)
      subscribers = :ets.lookup_element(:Followers, userid, 2)
      post_tweet_to_subscribers(tweetid, subscribers -- messageOrMentions)

      {:reply, {true, toMap(tweetid, tweet, userid, now)}, state}
      # {:reply, {true, tweet}, state}
    else
      {:reply, {false, messageOrMentions}, state}
    end
  end

  def handle_call({:query_by_subscribed_user, user, search}, _from, state) do
    result =
      Enum.reduce(
        Enum.map(:ets.lookup_element(:SubscribedTo, user, 2), fn user ->
          :ets.lookup_element(:Tweets, user, 2)
        end),
        [],
        fn tweets, acc -> tweets ++ acc end
      )

    {:reply, Enum.filter(result, fn x -> String.contains?(x, search) end), state}
  end

  def handle_call({:put_process_id, username, process_id}, _from, state) do
    :ets.insert(:ProcessMapping, {username, process_id})
    {:reply, state, state}
  end

  # login callback
  def handle_call({:login_user, {username, password}}, _from, state) do
    case :ets.lookup(:Users, username) do
      [_] ->
        storedPassword = :ets.lookup_element(:Users, username, 2)

        if storedPassword === password do
          # to check if user is logged in or not
          :ets.insert(:UserState, {username, true})
          {:reply, true, state}
        else
          {:reply, false, state}
        end

      [] ->
        {:error, false, state}
    end
  end

  # get tweets callback
  def handle_call({:get_tweets, {username}}, _from, state) do
    {:reply, :ets.lookup_element(:Tweets, username, 2), state}
  end

  # logout
  def handle_call({:logout, username}, _from, state) do
    :ets.insert(:UserState, {username, false})
    {:reply, true, state}
  end

  # def post_tweet_to_subscribers(tweet, from_user, subscribers) do
  def post_tweet_to_subscribers(tweetid, subscribers) do 
    [{tweetid, from_user, tweet, now}] = :ets.lookup(:TweetById, tweetid)
    subscribers = subscribers -- [from_user]

    Enum.each(subscribers, fn subscriber ->
      [listOfOldTweets] = :ets.lookup(:Notifications, subscriber)
      oldTweet = elem(listOfOldTweets, 1)
      newTweet = [tweet | oldTweet]

      if isUserLoggedIn(subscriber) do
        IO.puts("#{subscriber} received tweet #{tweet}")
        :ets.insert(:Notifications, {subscriber, newTweet})

        # Phoenix.Channel.push(:ets.lookup_element(:ProcessMapping, subscriber, 2), "notify", %{
        #  tweet: tweet,
        #   user: from_user
        # })
        Phoenix.Channel.push(:ets.lookup_element(:ProcessMapping, subscriber, 2), "notify", toMap(tweetid, tweet, from_user, now))
      end
    end)
  end

  defp toMap(tweetid, tweet, user, time) do
    %{
      tweetid: tweetid,
      tweet: tweet,
      user: user,
      time: time
    }
  end

  def process_tweet(tweet) do
    {:ok, mention} = Regex.compile("@[^#@\\s]*")
    mentions = Enum.uniq(Regex.scan(mention, tweet))

    mentions =
      Enum.map(mentions, fn [m] ->
        String.slice(m, 1..-1)
      end)

    all_registered = Enum.all?(mentions, fn n -> :ets.member(:Users, n) end)

    if all_registered do
      Enum.each(mentions, fn mention ->
        previous =
          if :ets.member(:Mentions, mention) do
            :ets.lookup_element(:Mentions, mention, 2)
          else
            []
          end

        :ets.insert(:Mentions, {mention, [tweet | previous]})
      end)

      {:ok, hashtag} = Regex.compile("#[^#@\\s]*")
      hashtags = Enum.uniq(Regex.scan(hashtag, tweet))

      Enum.each(hashtags, fn [hashtag] ->
        hashtag = String.slice(hashtag, 1..-1)

        previous =
          if :ets.member(:Hashtags, hashtag) do
            :ets.lookup_element(:Hashtags, hashtag, 2)
          else
            []
          end

        :ets.insert(:Hashtags, {hashtag, [tweet | previous]})
      end)

      {true, mentions}
    else
      {false, "All users not registered"}
    end
  end

  # return the logged in state , return true if logged in else returns false
  def isUserLoggedIn(username) do
    if(
      :ets.lookup(:UserState, username) == [] ||
        :ets.lookup_element(:UserState, username, 2) == false
    ) do
      false
    else
      :ets.lookup_element(:UserState, username, 2)
    end
  end

  def print_table(table) do
    IO.inspect(:ets.tab2list(String.to_atom(table)))
  end

  def save_process_id(username, process_id) do
    GenServer.call(:server, {:put_process_id, username, process_id})
  end

end
