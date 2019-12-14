defmodule TwitterEngineWeb.EngineChannel do
  use Phoenix.Channel
  import Logger

  def join("twitter", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("register_user", payload, socket) do
    {isSuccess, message} = TwitterEngine.ServerInterface.register(payload["user"], payload["password"])

    if isSuccess do
      {:reply, {:ok, %{message: message}}, socket}
    else
      {:reply, {:error, %{message: message}}, socket}
    end
  end

  def handle_in("login_user", payload, socket) do
    {isSuccess, message} = TwitterEngine.ServerInterface.login(payload["user"], payload["password"])

    if isSuccess do
      TwitterEngine.ServerInterface.save_process_id(payload["user"], socket)
      {:reply, {:ok, %{message: message}}, socket}
    else
      {:reply, {:error, %{message: message}}, socket}
    end
  end

  def handle_in("tweet", payload, socket) do
    username = payload["user"]
    tweet = payload["tweet"]

    {success, message} = TwitterEngine.ServerInterface.tweet(username, tweet)

    if success do
      {:reply, {:ok, %{message: message}}, socket}
    else
      {:reply, {:error, %{message: message}}, socket}
    end
  end

  def handle_in("logout_user", payload, socket) do
    TwitterEngine.ServerInterface.logout(payload["user"])
    {:reply, {:ok, %{message: "Logout Successful"}}, socket}
  end

  def handle_in("subscribe_user", payload, socket) do
    {isSuccess, message} =
      TwitterEngine.ServerInterface.subscribe_user(payload["user"], payload["following"])

    if isSuccess do
      {:reply, {:ok, %{message: message}}, socket}
    else
      {:reply, {:error, %{message: message}}, socket}
    end
  end

  def handle_in("search_tweets_by_hashtag", hashtag, socket) do
    {isSuccess, result} = TwitterEngine.ServerInterface.search_tweets_by_hashtag(hashtag)

    if isSuccess do
      {:reply, {:ok, %{result: result}}, socket}
    else
      {:reply, {:error, %{result: result}}, socket}
    end
  end

  def handle_in("search_my_mentions", mention, socket) do
    {isSuccess, result} = TwitterEngine.ServerInterface.search_my_mentions(mention)

    if isSuccess do
      {:reply, {:ok, %{result: result}}, socket}
    else
      {:reply, {:error, %{result: result}}, socket}
    end
  end

  def handle_in("retweet", payload, socket) do
    username = payload["user"]
    tweet_id = payload["tweet_id"]

    {success, message} = TwitterEngine.ServerInterface.retweet(username, tweet_id)

    if success do
      {:reply, {:ok, %{message: message}}, socket}
    else
      {:reply, {:error, %{message: message}}, socket}
    end
  end
  
end
