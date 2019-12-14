defmodule TwitterEngine.ServerInterface do
  import Logger

  def register(username, password) do
    {isSuccess, message} =
      GenServer.call(:server, {:register_user, {username, password}}, :infinity)

    if(isSuccess) do
      Logger.debug("registration successful for #{username}")
    else
      Logger.debug("#{username} already registered")
    end

    {isSuccess, message}
  end

  def login(username, password) do
    if is_user_registered(username) == false do
      {false, "user not registered"}
    else
      if(GenServer.call(:server, {:login_user, {username, password}}, :infinity)) do
        Logger.debug("login successful for #{username}")
        {true, "Login Successful"}
      else
        Logger.debug("Password incorrect")
        {false, "Password incorrect"}
      end
    end
  end

  def save_process_id(username, process_id) do
    TwitterEngine.Server.save_process_id(username, process_id)
  end

  def logout(username) do
    GenServer.call(:server, {:logout, username}, :infinity)
  end

  def tweet(username, tweet) do
    {success, message} = GenServer.call(:server, {:tweet, {username, tweet, "tweet"}}, :infinity)

    if success do
      IO.puts("#{tweet} posted")
      {true, "Tweet posted"}
    else
      {false, message}
    end
  end

  defp is_user_registered(username) do
    GenServer.call(:server, {:is_user_registered, username}, :infinity)
  end

  def subscribe_user(username, subscribe) do
    if GenServer.call(:server, {:subscribe_user, {subscribe, username}}) do
      {true, "Successfully Subsribed"}
    else
      {false, "Error"}
    end
  end

  def search_tweets_by_hashtag(hashtag) do
    result = GenServer.call(:server, {:search_tweets_by_hashtag, hashtag})
    if(result==[]) do
      {false,result}
    else
      {true, result}
    end
  end

  def search_my_mentions(mention) do
    result = GenServer.call(:server, {:search_my_mentions, mention})
    if(result=="No tweets with myMentions found") do
      {false,result}
    else
      {true, result}
    end
  end

  def retweet(username, tweet_id) do
    [{_tweet_id, user, tweet, _time}] = :ets.lookup(:TweetById, String.to_integer(tweet_id))

    {success, message} =
      GenServer.call(:server, {:tweet, {username, tweet, "retweet"}}, :infinity)

    if success do
      tweet = user <> ": " <> Map.get(message, :tweet)
      message = Map.put(message, :tweet, tweet)
      {true, message}
    else
      {false, message}
    end
  end

end
