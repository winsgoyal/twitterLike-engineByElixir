defmodule Client  do 
  use GenServer
  
  def start_link(n) do
    GenServer.start_link(__MODULE__, %{user_name: n },name: String.to_atom(n) )
    
    # get_in(users, ["john", :age])
    # put_in(users.obj["2344"],["a"])
  
  end
  
  def init(state) do

   

    {:ok, state}
  end
  
  def get(pid) do  
    GenServer.call(pid, :get, :infinity)
  end
  
  def set(pid) do  
    GenServer.call(pid, :set, :infinity)
  end
  
  def register(pid, user, password) do
    GenServer.call(pid, {:register, user, password})
  end

  def login(pid, user, password) do
    GenServer.call(pid, {:login, user, password})
  end

  #User will tweet, this function then connect to server
  def tweet(pid, user, tweet) do
    GenServer.call(pid, {:tweet, user , tweet })
  end

  def subscribe_to(pid, user, subscribe_to_user) do
    GenServer.call(pid, {:subscribe_to, user, subscribe_to_user})
  end

 
  # this function will receive tweets from server upon login (mostly) and set the user tweets table
  def receive_tweets(pid , tweets)  do
    GenServer.cast(pid, {:receive_tweets, tweets})
  end
  
  def set_state(pid, nodeid, routing_table) do  
    GenServer.cast(pid, {:set_state,routing_table,nodeid})
  end
  
  #User will tweet, this function then connect to server
  def search(pid, search_text) do
    GenServer.cast(pid, {:search, search_text })
  end

  #function to insert values into mention table
  defp insert_in_mention( user , tweet )  do

    user_mentions = :ets.lookup(:mention, user)
    if length(user_mentions) == 0 do
      :ets.insert_new(:mention, {user,  [tweet] })
    else
     [ {user, tweets} ] =  user_mentions
    :ets.insert_new(:mention, {user, tweets ++ [tweet] })
    end
    
  end

  #function to insert values into notification table
  defp insert_in_notification( user , tweet )  do

    user_notifications = :ets.lookup(:notification, user)
    if length(user_notifications) == 0 do
      :ets.insert_new(:notification, {user,  [tweet] })
    else
     [ {user, tweets} ] =  user_notifications
    :ets.insert_new(:notification, {user, tweets ++ [tweet] })
    end
    
  end

   #it will receive notification and store the tweets in notification
   # if user is mentioned than stored in mentioned table
   def handle_cast({:notification, tweet , message } , %{user_name: user} = state ) do
    IO.puts "Notification" <> message
    if String.contains?(tweet, "@" ) do
      insert_in_mention(user, tweet)
    else
      insert_in_notification(user, tweet)
    end
    
    {:noreply, state }    
  end



   #initialize user tweets, if any received from server
   def handle_cast(  {:search, search_text } , state ) do
    {:ok, _result, _ } = TwitterServer.search(search_text) ;
    {:noreply, state }    
  end
  #initialize user tweets, if any received from server
  def handle_cast({:receive_tweets, tweets} , %{user_name: user} =state ) do
      :ets.insert_new(:client_tweet, { user, tweets })
      {:noreply, state }    
  end

  def handle_call({:subscribe_to, user, subscribe_to_user}, _from, state) do
    result = TwitterServer.subscribe_user(user, subscribe_to_user)
    IO.inspect result
    if result == 'ok' do
      IO.puts "User " <> user <> " has succefully subscribe the user " <> subscribe_to_user
    end
    {:reply, state, state }
  end

  def handle_call( {:tweet, user, tweet} , _from ,state) do
    result = TwitterServer.tweet( user , tweet )
    if result == "pass" do
      IO.puts "User " <> user <>" has tweeted " <> tweet
      tweets = :ets.lookup(:client_tweet, user)
      :ets.insert_new(:client_tweet, {user, tweets ++ [tweet] })
    else
      IO.puts "tweet is empty or please try again"
    end
    {:reply, state, state, :infinity}  
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state, :infinity}
  end

  def handle_call({:register, user, password}, _from, state) do
    TwitterServer.register( user, password ) ;
    {:reply,state, state, :infinity}
  end

  def handle_call({:login, user, password}, _from, state) do
    #{:reply, result, state} = 
    result =  TwitterServer.login( user, password , self() )
    
    if result == "pass" do
      :ets.insert_new(:client_tweet, {user, []})
      :ets.insert_new(:notification, {user, []})
      IO.puts "User " <> user <> " Login Success"
    else
      IO.puts "Login Failed, Please check Credentials"
    end

    {:reply, state, state, :infinity}
  end


  
  def handle_call(:set, _from, state) do
    {:reply, state, [], :infinity}
  end
   
end
