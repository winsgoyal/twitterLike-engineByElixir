defmodule TwitterEngine.Client do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(init_arg) do
    {:ok, {String.replace(init_arg, "user", ""), []}}
  end

  # Directly Calls the server
  def register(username, password) do
    {isSuccess, message} =
      GenServer.call(:server, {:register_user, {username, password}}, :infinity)

    if(isSuccess) do
      IO.puts("registration successful for #{username}")
    else
      IO.puts("#{username} already registered")
    end

    {isSuccess, message}
  end

  def show_followers(user) do
    GenServer.call(String.to_atom(user), {:show_followers, user}, :infinity)
  end

  def query_by_hashtag(hashtag) do
    GenServer.call(:server, {:query_by_hashtag, hashtag}, :infinity)
  end

  def query_by_mention(mention) do
    GenServer.call(:server, {:query_by_mention, mention}, :infinity)
  end

  def query_by_subscribed_user(user, search) do
    GenServer.call(String.to_atom(user), {:query_by_subscribed_user, user, search}, :infinity)
  end

  def add_follower(username, follower) do
    GenServer.call(String.to_atom(username), {:add_follower, {username, follower}}, :infinity)
  end

  def handle_call({:query_by_subscribed_user, user, search}, _from, state) do
    {:reply, GenServer.call(:server, {:query_by_subscribed_user, user, search}, :infinity), state}
  end

  def handle_call({:show_followers, username}, _from, state) do
    {:reply, GenServer.call(:server, {:show_followers, username}, :infinity), state}
  end

  def handle_call({:retweet, {tweetId, userId}}, _from, userState) do
    tweet = GenServer.call(:server, {:get_tweet_by_id, tweetId}, :infinity)
    GenServer.call(:server, {:tweet, {userId, tweet, "retweet"}}, :infinity)
    {:reply, tweet, userState}
  end

  def handle_call({:get_tweet_by_Id, {tweetId}}, _from, userState) do
    {:reply, GenServer.call(:server, {:get_tweet_by_id, tweetId}, :infinity), userState}
  end

  def handle_call({:tweet, {userid, tweet, flag}}, _from, state) do
    {:reply, GenServer.call(:server, {:tweet, {userid, tweet, flag}}, :infinity), state}
  end

  def handle_call({:logout, username}, _from, {user, _}) do
    {:reply, GenServer.call(:server, {:logout, username}, :infinity), {user, []}}
  end

  def handle_call({:add_follower, {username, follower}}, _from, state) do
    if is_user_registered(follower) do
      {:reply, GenServer.call(:server, {:add_follower, {username, follower}}, :infinity), state}
    else
      {:reply, {false, "#{follower} not registered"}, state}
    end
  end

  def handle_call({:subscribed_tweets}, _from, {user, subscribed_tweets}) do
    {:reply, subscribed_tweets, {user, subscribed_tweets}}
  end

  def tweet(username, tweet) do
    if(Server.isUserLoggedIn(username) == true) do
      {success, message} =
        GenServer.call(String.to_atom(username), {:tweet, {username, tweet, "tweet"}}, :infinity)

      if success do
        IO.puts("#{tweet} posted")
        {true, "Success"}
      else
        {false, message}
      end
    else
      {false, "User not logged in"}
    end
  end

  def delete(username) do
    GenServer.call(:server, {:delete, username}, :infinity)
  end

  def is_user_registered(username) do
    GenServer.call(:server, {:is_user_registered, username}, :infinity)
  end

  def login(username, password) do
    if is_user_registered(username) == false do
      {false, "user not registered"}
    else
      if(GenServer.call(:server, {:login_user, {username, password}}, :infinity)) do
        IO.puts("login successful for #{username}")
        {true, "Login Successful"}
      else
        IO.puts("Password incorrect")
        {false, "Password incorrect"}
      end
    end
  end

  def retweet(username, tweetid) do
    GenServer.call(String.to_atom(username), {:retweet, {tweetid, username}}, :infinity)
  end

  def get_tweets(username) do
    if(Server.isUserLoggedIn(username) == true) do
      GenServer.call(:server, {:get_tweets, {username}}, :infinity)
    else
      "Not logged in"
    end
  end

  def logout(username) do
    if Process.whereis(String.to_atom(username)) == nil do
      {false, "User not logged in"}
    else
      {GenServer.call(String.to_atom(username), {:logout, username}, :infinity),
       "Logout successful"}
    end
  end

  def subscribed_tweets(user) do
    GenServer.call(String.to_atom(user), {:subscribed_tweets})
  end

  def handle_cast({:notify_tweet, tweet, tweetid}, {user, subscribed_tweets}) do
    {:noreply, {user, [{tweet, tweetid} | subscribed_tweets]}}
  end

  def handle_cast({:start_toggle}, state) do
    IO.puts "Start Toggle"
    send(self(), {:toggle})
    {:noreply, state}
  end

  def handle_info({:toggle}, {user, _tweets}) do
    if Server.isUserLoggedIn("user#{user}") do
      IO.puts "Logout in between"
      GenServer.call(:server, {:logout, "user#{user}"}, :infinity)
    else
      IO.puts "Login in between"
      GenServer.call(:server, {:login_user, {"user#{user}", "pass#{user}"}}, :infinity)
    end

    Process.send_after(self(), {:toggle}, Enum.random(1..5) * 100)
    {:noreply, {user, []}}
  end
end
