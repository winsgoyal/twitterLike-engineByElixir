defmodule TwitterServer do 
    use GenServer

    def start_link() do
        GenServer.start_link(__MODULE__, {0},name: __MODULE__ )
    end

    def init(state) do
      
      ## Table: User
      ## {user, password, logged_in_status}
      :ets.new(:user, [:set, :protected, :named_table])
      
      ## Table: Tweet
      ## {tweet, user, mention_list, hashstag_list, liked_by_users_list}
      :ets.new(:tweet, [:set, :protected, :named_table])

      ## Table: Subscribe
      ## {user, liked_tweets_list, subscribed_to_user_list, subscribed_by_user_list, subscribed_to_hashtag_list}
      :ets.new(:subscribe, [:set, :protected, :named_table])

      ## Table: Hashtag
      ## {hashtag, subscribed_by_user_list}
      :ets.new(:hashtag, [:set, :protected, :named_table])

      :ets.new(:pending_notifiaction, [:set, :protected, :named_table])

      {:ok, state}
    end

    def get() do  
      GenServer.call(__MODULE__, :get, :infinity)
    end

    def register(user, password) do
      GenServer.call(__MODULE__, {:register,user, password})
    end

    def login(user , password , pid ) do
      GenServer.call(__MODULE__, {:login,user , password , pid})
    end

    def delete(user) do
      GenServer.cast(__MODULE__, {:register,user})
    end

    def search(search_string, hash_tag) do
      GenServer.cast(__MODULE__, {:register,search_string , hash_tag})
    end

    #will deliver new tweets, mentions
    def deliver(user) do
      GenServer.cast(__MODULE__, {:register,user })
    end
    
    def tweet(user, tweet_text) do
      GenServer.call(__MODULE__, {:tweet,user, tweet_text })
    end

    # When user retweet some tweet, then that tweet will appear in
    # other users(subscriber) feed
    def re_tweet(user, tweet_id) do
      GenServer.cast(__MODULE__, {:re_tweet,user, tweet_id })
    end

    # user will subscribe to subscribe_to_user
    def subscribe_user(user, subscribe_to_user) do
      GenServer.cast(__MODULE__, {:subscribe_user, user, subscribe_to_user})
    end

    # send notifications to the subscribe users 
    #user_list is list of users who have subscribed to user tweeter_owner
    def notify_subscribers( tween_owner , tweet) do
      GenServer.cast(__MODULE__, {:notify, tween_owner, tweet})
    end

    # send notifications to the mentioned users 
    #user_list is list of users who is mentioned in the tweet
    def notify_mentioned_users( tween_owner , tweet) do

      if String.contains?(tweet, "@" ) do
        GenServer.cast(__MODULE__, {:notify, tween_owner, tweet})
      end
      
    end


    

    #to asend notification to subscriber
  def handle_cast({:notify_subscribers, tweet_owner, tweet} , _state) do
    
    #get list of subscribe by user
    {tweet_owner, subscribedby} = :ets.lookup(:subscribe, tweet_owner)
    if length(subscribedby) > 0 do
      Enum.each( subscribedby, fn user -> 
        {user,_,_,pid} = :ets.lookup(:user, user)
        GenServer.cast(pid, {:notification, tweet , tweet_owner <> " has tweeted " })
      
      end)
    end
    {:noreply, state }    
  end

    #to asend notification to subscriber
    def handle_cast({:notify_mentioned_users, tweet_owner, tweet} , _state) do
    
      #get list of subscribe by user
      mentioned_user = Regex.scan(~r/@([a-zA-z0-9]*)/,s)
      if length(mentioned_user) > 0 do
        Enum.each( mentioned_user, fn [_,user] -> 
          {user,_,login_flag,pid} = :ets.lookup(:user, user)
          if login_flag == 1 do
            GenServer.cast(pid, {:notification, tweet , tweet_owner <> " has tweeted " })
          else
            #add it the pending notification list list
            #deliver these when users gets back online
            add_pending_notification( user , tweet , tweet_owner <> " has tweeted " )

          end

        
        end)
      end
      {:noreply, state }    
    end

    defp add_pending_notification ( user, tweet , message ) do
      user_pending_notification = :ets.lookup(:pending_notifiaction, user)

      if length(user_pending_notification) > 0 do
         {user , notifications} = user_pending_notification
         notifications ++ [[tweet , message]]
        :ets.insert_new(:pending_notifiaction, {user , notifications} ) 
      else
        :ets.insert_new(:pending_notifiaction, {user, [[tweet , message]]}) 
      end
    end

    defp send_pending_notification (user) do
      user_pending_notification = :ets.lookup(:pending_notifiaction, user)

      if length(user_pending_notification) > 0 do
         {user , notifications} = user_pending_notification
         
         if length(notifications) > 0 do
            Enum.each( notifications, fn [tweet,message] ->  
              GenServer.cast(pid, {:notification, tweet , message }) 
            end)
         end
        :ets.insert_new(:pending_notifiaction, {user , notifications} ) 
      else
        :ets.insert_new(:pending_notifiaction, {user, [[tweet , message]]}) 
      end
    end

    end

    def handle_call({:register, user, password}, _from, state) do
      
      # existing_usres_map = :ets.lookup(:user, "users")
      # existing_usres_map = %{ existing_usres_map | user => [password, 0] }
      # existing_usres_map = Map.put(existing_usres_map, "a", 100)
      user_details = :ets.lookup(:user, user)
      if length(user_details) > 0 do
        IO.inspect "Username #{user} already exists"
        {:reply, "fail", state}
      else
        :ets.insert_new(:user, {user, password, 0, 0})
        IO.inspect "Username #{user} Created"
        {:reply, "pass", state}
      end 

      
    end

    #change pid to gproc, as pid can change, if spervisor restarts user process
    def handle_call({:login, user, password , pid }, _from, state) do
      
      # existing_usres_map = :ets.lookup(:user_lookup, "users")
      # user_details = Map.get( existing_usres_map , user) 
      user_details = :ets.lookup(:user, user)
      if length(user_details) >  0 do
        # user exists and password matches
        # update the map to have loginflag as 1
        # existing_usres_map = %{ existing_usres_map | user => [password,1] }
        [ {user, stored_password, _ , _ } ] = user_details
        if stored_password == password do
          :ets.insert_new(:user, {user, password, 1, pid})
          intitialize(user)
          #IO.inspect "User #{user} Login Successfull"
          Genserver.cast({:receive_tweets, })
          ## add pending login functionality here 
          {:reply, "pass", state}
        else
          IO.puts "User name/ password is not correct"
          {:reply, "fail", state}
        end
      else
        IO.puts "User name/ password is not correct"
        {:reply, "fail", state}
      end
      
      
    end

    defp intialize(user) do
      # do all the intialization if tables are empty
    end

    ## As soon as the user subscribes to another user,
    ## (a) Update Another User's {Subscribed_by_users_list}
    ## (b) The notification should go to the Another User who's being subscribed by the user. (How??)
    def handle_call({:subscribe_user, user, subscribe_to_user}, _from, state) do
      subscribe_details = :ets.lookup(:subscribe, user)

      if length(subscribe_details) == 0 do
        :ets.insert_new(:subscribe, {user, [], [subscribe_to_user], [], []})
        IO.inspect "User #{user} subscribed to User #{subscribe_to_user}"
      else
        [ {user, liked_tweets, subscribed_to_users, subscribed_by_users, subscribed_hashtags} ] = subscribe_details
        subscribed_to_users = subscribed_to_users ++ [subscribe_to_user]
        :ets.insert(:subscribe, {user, liked_tweets, subscribed_to_users, subscribed_by_users, subscribed_hashtags})
        IO.inspect "User #{user} subscribed to User #{subscribe_to_user}"
      end

      subscribed_by(subscribe_to_user, user)
      
      {:reply, state, state}
    end

    # user will be subscribed_by_user
    defp subscribed_by(user, subscribed_by_user) do
      subscribe_details = :ets.lookup(:subscribe, user)
      
      if length(subscribe_details) == 0 do
        :ets.insert_new(:subscribe, {user, [], [], [subscribed_by_user], []})
        IO.inspect "User #{user} subscribed by User #{subscribed_by_user}"
      else
        [ {user, liked_tweets, subscribed_to_users, subscribed_by_users, subscribed_hashtags} ] = subscribe_details
        subscribed_by_users = subscribed_by_users ++ [subscribed_by_user]
        :ets.insert(:subscribe, {user, liked_tweets, subscribed_to_users, subscribed_by_users, subscribed_hashtags})
        IO.inspect "User #{user} subscribed by User #{subscribed_by_user}"
      end
    end

    def handle_call({:tweet,user, tweet_text } ,_from,state) do
        #IO.puts (Enum.at(list,length(list) -1 ) - start_time)

        if String.length( tweet_text ) > 0 do
          #get old tweets and so that we can update the list
          {user, user_tweets} = :ets.lookup(:tweet, user)
          
          :ets.insert_new(:tweet, {user, user_tweets ++ [tweet_text] })
          {:reply, "pass", state}
        else
          {:reply, "fail", state}
        end
        
    end

    def handle_call(:get,_from,state) do
      #IO.puts (Enum.at(list,length(list) -1 ) - start_time)
      {:reply, state, state}
  end

    

end
