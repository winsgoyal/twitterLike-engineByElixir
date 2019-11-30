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
    GenServer.call(pid, {:register, user, password} , :infinity)
  end

  def login(pid, user, password) do
    GenServer.call(pid, {:login, user, password}, :infinity)
  end

  def logout(pid, user) do
    GenServer.call(pid, {:logout, user}, :infinity)
  end

  #User will tweet, this function then connect to server
  def tweet(pid, user, tweet) do
    GenServer.call(pid, {:tweet, user , tweet } , :infinity)
  end

  def subscribe_to(pid, user, subscribe_to_user) do
    #IO.puts "Debug subscribe_to"
    #IO.inspect user
    GenServer.call(pid, {:subscribe_to, user, subscribe_to_user} , :infinity)
  end

 
  # this function will receive tweets from server upon login (mostly) and set the user tweets table
  def receive_tweets(pid , tweets)  do
    GenServer.cast(pid, {:receive_tweets, tweets} , :infinity)
  end
  
  def set_state(pid, nodeid, routing_table) do  
    GenServer.cast(pid, {:set_state,routing_table,nodeid} )
  end
  
  #User will tweet, this function then connect to server
  def search(pid, search_text) do
    GenServer.call(pid, {:search, search_text } , :infinity)
  end
 
  def deactivate(pid, user) do
    GenServer.call(pid, {:deactivate, user } , :infinity)
  end

  # this function will retweet tweets from server upon login (mostly) and set the user tweets table
  def retweet_tweet(pid , tweet , tweet_owner , index)  do
    if String.length(tweet) > 0 do
      GenServer.call(pid, {:retweet_tweet, tweet , tweet_owner , index} , :infinity)
    end
  end

  def get_random_tweet_from_notification(user) do
      user_notification = :ets.lookup(:notification, user)

      if length(user_notification) == 0 do
        []
      else
        [ {_user,tweets} ] = user_notification
        if length(tweets) > 0 do
          #IO.puts length(tweets)
          
          tweet = Enum.take_random(tweets,1)
          #IO.inspect tweet
          tweet
        else
          []
        end
        
        
      end
  end



  #function to insert values into mention table
  defp insert_in_mention( user , tweet , index )  do

    user_mentions = :ets.lookup(:mention, user)
    if length(user_mentions) == 0 do
      :ets.insert_new(:mention, {user,  [tweet] })
    else
     [ {user, tweets} ] =  user_mentions
    :ets.insert_new(:mention, {user, tweets ++ [tweet] })
    end
    
  end

  #function to insert values into notification table
  defp insert_in_notification( user , tweet, tweet_owner , index )  do

    user_notifications = :ets.lookup(:notification, user)
    #IO.puts "Debug insert_in_notification"
    #IO.inspect tweet
    #IO.puts user
    if length(user_notifications) == 0 do
      :ets.insert_new(:notification, {user,  [[tweet,tweet_owner , index]] })
    else
     [ {user, tweets} ] =  user_notifications
    :ets.insert(:notification, {user, tweets ++ [[tweet,tweet_owner , index]] })
    end
    
  end

   #it will receive notification and store the tweets in notification
   # if user is mentioned than stored in mentioned table
   def handle_cast({:notification, tweet , tweet_owner, index,  message } , %{user_name: user} = state ) do
    IO.puts "User " <> user <> " Notification: " <> message
    if String.contains?(tweet, "@" ) do
      insert_in_mention(user, tweet , index)
    else
      insert_in_notification(user, tweet, tweet_owner , index)
    end
    
    {:noreply, state }    
  end
    
  
  def handle_call({:deactivate, user } , _from, %{user_name: user} = state ) do
    
    #server will add to retweet list notify the user subscribers if any
    result = TwitterServer.delete( user  ) 
    if result == "pass" do
      IO.puts "User " <> user <> "  deleted successfully "
      {:reply, "pass", state}  
    else
      IO.puts "User " <> user <> " delettion unsucesesfull"
      
      {:reply, "fail", state}  
    end
     
  end

    #it will receive notification and store the tweets in notification
   # if user is mentioned than stored in mentioned table
   def handle_call({:retweet_tweet, tweet , tweet_owner , index} , _from, %{user_name: user} = state ) do
    
    #server will add to retweet list notify the user subscribers if any
    result = TwitterServer.re_tweet( user , tweet_owner , index ) 
    if result == "pass" do
      IO.puts "User " <> user <> "  has retweeted the tweet " <> tweet
      {:reply, "pass", state}  
    else
      IO.puts "User " <> user <> " retweet " <> tweet <> " unsuccesull, Please try again"
      {:reply, "fail", state}  
    end
     
  end


   #initialize user tweets, if any received from server
   def handle_call(  {:search, search_text } , _from , state ) do
    result = TwitterServer.search(search_text) ;
    IO.puts "Found tweets with given search string " <>  search_text
    IO.inspect result
    {:reply, result ,  state }    
  end
  #initialize user tweets, if any received from server
  def handle_cast({:receive_tweets, tweets} , %{user_name: user} =state ) do
      :ets.insert_new(:client_tweet, { user, tweets })
      {:noreply, state }    
  end

  def handle_call({:subscribe_to, user, subscribe_to_user}, _from, state) do
    result = TwitterServer.subscribe_user(user, subscribe_to_user)
    #IO.puts "Debug subscribe_to"
    #IO.inspect user
    if result == "pass" do
      IO.puts "User " <> user <> " has succefully subscribe the user " <> subscribe_to_user
      {:reply, "pass", state }
    else
      {:reply, "fail" , state }
    end
    
  end

  def handle_call( {:tweet, user, tweet} , _from ,state) do
    result = TwitterServer.tweet( user , tweet )
    if result == "pass" do
      IO.puts "User " <> user <>" has tweeted " <> tweet
      tweets = :ets.lookup(:client_tweet, user)
      :ets.insert_new(:client_tweet, {user, tweets ++ [tweet] })
      {:reply, "pass", state, :infinity}  
    else
      IO.puts "tweet is empty or please try again"
      {:reply, "fail", state, :infinity}  
    end
   
  end



  def handle_call(:get, _from, state) do
    {:reply, state, state, :infinity}
  end

  def handle_call({:register, user, password}, _from, state) do
    result = TwitterServer.register( user, password )

    if result == "pass" do
      {:reply,"pass", state, :infinity}
    else
      {:reply, "fail", state ,  :infinity}
    end
    
  end

  def handle_call({:login, user, password}, _from, state) do
    #{:reply, result, state} = 
    result =  TwitterServer.login( user, password , self() )
    
    if result == "pass" do
      :ets.insert_new(:client_tweet, {user, []})
      :ets.insert_new(:notification, {user, []})
      IO.puts "User " <> user <> " Login Success"
      {:reply, "pass", state, :infinity}

    else
      IO.puts "Login Failed, Please check Credentials"
      {:reply, "fail", state, :infinity}
    end

   
  end

  def handle_call({:logout, user}, _from, state) do
    #{:reply, result, state} = 
    result =  TwitterServer.logout( user  )
    
    if result == "pass" do
      :ets.insert(:client_tweet, {user, []})
      :ets.insert(:notification, {user, []})
      IO.puts "User " <> user <> " Logout Success"
      {:reply, "pass", state, :infinity}
    else
      IO.puts "Logout Failed, Please try again"
      {:reply, "pass", state, :infinity}
    end

    
  end
  
  
  def handle_call(:set, _from, state) do
    {:reply, state, [], :infinity}
  end
   
end
