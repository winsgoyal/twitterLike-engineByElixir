defmodule TwitterServer do 
    use GenServer

    def start_link() do
        GenServer.start_link(__MODULE__, {tweet_count = 0},name: __MODULE__ )
    end

    def init(state) do
      
      ## Table: User
      ## {user, password, logged_in_status, }
      :ets.new(:user, [:set, :protected, :named_table])
      
      ## Table: Tweet
      ## {tweet, user, mentions_list, hashstags_list}
      :ets.new(:tweet, [:set, :protected, :named_table])

      #retweet, will contains which users has retweeted what tweets
      #format user is key, [[tweet_owner, tweet_index]]
      :ets.new(:retweet, [:set, :protected, :named_table])
      ## Table: Subscribe
      ## {user, subscribed_by_users_list}
      :ets.new(:subscribe, [:set, :protected, :named_table])

      :ets.new(:pending_notifiaction, [:set, :protected, :named_table])

      #store user and its mentiones tweet indexs in respective table rows
      :ets.new(:mention, [:set, :protected, :named_table])

      #store hashtag and tweets conatining this hashtag indexs in respective table rows
      :ets.new(:hashtag, [:set, :protected, :named_table])

      #predefined list of hashtags
      hashtag_list = ["#dos","#twitter", "#project4", "#victory" , "#goal" , "#focus"]


      Enum.each(hashtag_list , fn hash_tag -> 
        :ets.insert_new(:hashtag, {hash_tag , []} ) 
      end)
      

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

    def logout( user ) do
      GenServer.call(__MODULE__, {:logout, user })
    end

    def delete(user) do
      GenServer.call(__MODULE__, {:delete,user})
    end

    def search(search_text) do
      if String.contains?(search_text, "#" ) do
        GenServer.call(__MODULE__, {:search_by_hashtag,search_text})
      else
        GenServer.call(__MODULE__, {:search_by_user,search_text})
      end
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
    def re_tweet(user, tweet_owner , tweet_id) do
      GenServer.call(__MODULE__, {:re_tweet, user, tweet_owner , tweet_id})
    end

    # user will subscribe to subscribe_to_user
    def subscribe_user(user, subscribe_to_user) do
      GenServer.call(__MODULE__, {:subscribe_user, user, subscribe_to_user})
    end

    # send notifications to the subscribe users 
    #user_list is list of users who have subscribed to user tweeter_owner
    def notify_subscribers(user , tweet_owner, tweet, index , message \\ "") do
      GenServer.cast(__MODULE__, {:notify_subscribers, user , tweet_owner, tweet , index , message})
    end

    # send notifications to the mentioned users 
    # user_list is list of users who is mentioned in the tweet
    def notify_mentioned_users(tweet_owner, tweet) do

      if String.contains?(tweet, "@" ) do
        GenServer.cast(__MODULE__, {:notify, tweet_owner, tweet})
      end
      
    end


    

    # to send notification to subscriber
    def handle_cast({:notify_subscribers, user, tweet_owner, tweet , index , message} , state) do
      
      # get list of subscribe by user
      subscribers = get_subscribers(user)

      if length(subscribers) > 0 do
        Enum.each( subscribers, fn user -> 
          #IO.puts "Debug Subscriber" <> user
          #IO.inspect :ets.lookup(:user , user)
          # :timer.sleep(4000);
          [ {_user, _, _, pid} ] = :ets.lookup(:user, user)
          if message != "" do
            GenServer.cast(pid, {:notification, tweet, tweet_owner, index,   message})
          else
            GenServer.cast(pid, {:notification, tweet, tweet_owner, index,   "User " <> user <> " has tweeted "})
          end
        end)
      end
      {:noreply, state }    
    end

     #will return the list of tweets in which user is mentioned
     defp get_subscribers(user) do
      
      user_subscribers = :ets.lookup(:subscribe, user)

      if length(user_subscribers) == 0 do
        []
      else
        [ {_user, subscribers} ]= user_subscribers
        subscribers
      end

    end

   
    

    #to send notification to subscriber
    def handle_cast({:notify_mentioned_users, tweet_owner, tweet} , state) do
    
      #check if contains anu user mentions
      mentioned_user = Regex.scan(~r/@([a-zA-z0-9]*)/,tweet)
      if length(mentioned_user) > 0 do
        Enum.each( mentioned_user, fn [_,user] -> 
          [ {user, _, login_flag, pid} ] = :ets.lookup(:user, user)
          if login_flag == 1 do
            GenServer.cast(pid, {:notification, tweet , tweet_owner , tweet_owner <> " has tweeted"})
          else
            #add it the pending notification list list
            #deliver these when users gets back online
            add_pending_notification( user, tweet, tweet_owner <> " has tweeted")
          end
          user_mentions = :ets.lookup(:mention, user)
          if  length(user_mentions) > 0 do
            [{ user, mention_tweets } ] = user_mentions
            :ets.insert_new(:mention , {user, mention_tweets ++ [tweet] })
          else 
            :ets.insert_new(:mention , {user, [tweet] })
          end
          :ets.insert_new(:mention, {user , tweet} ) 
        end)
      end
      {:noreply, state }    
    end

    defp add_pending_notification(user, tweet, message) do
      user_pending_notification = :ets.lookup(:pending_notifiaction, user)

      if length(user_pending_notification) > 0 do
        [ {user , notifications} ] = user_pending_notification
        notifications = notifications ++ [[tweet , message]]
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
            
            {_user , _ , _ , pid} = :ets.lookup(:user , user)
            Enum.each( notifications, fn [tweet,message] ->  
              GenServer.cast(pid, {:notification, tweet , +message }) 
            end)
          end
         
      end
    end



    

    #this function will notify the subscribers of user, if tweets any particular tweet
    def handle_call({:re_tweet, user, tweet_owner , tweet_id}, _from, state) do
      
      # existing_usres_map = :ets.lookup(:user, "users")
      # existing_usres_map = %{ existing_usres_map | user => [password, 0] }
      # existing_usres_map = Map.put(existing_usres_map, "a", 100)
      tweet = get_user_tweet_at_index(tweet_owner , tweet_id)
      if String.length(tweet) > 0 do

        #add retweet to retweet tables
        add_retweet(user , tweet_owner, tweet_id)
        notify_subscribers(user ,tweet_owner , tweet ,tweet_id , "User " <> user <> " has re-tweeted " <> tweet)
        
        {:reply, "pass", state}
      else
        
        IO.inspect "retweet fail for user " <> user 
        {:reply, "fail", state}
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

    # change pid to gproc, as pid can change, if supervisor restarts user process
    def handle_call({:login, user, password, pid }, _from, state) do
      
      # existing_usres_map = :ets.lookup(:user_lookup, "users")
      # user_details = Map.get( existing_usres_map , user) 
      user_details = :ets.lookup(:user, user)
      if length(user_details) > 0 do
        # user exists and password matches
        # update the map to have loginflag as 1
        # existing_usres_map = %{ existing_usres_map | user => [password,1] }
        [ {user, stored_password, _ , _} ] = user_details
        if stored_password == password do
          :ets.insert(:user, {user, password, 1, pid})
          initialize(user)
          #IO.initialize "User #{user} Login Successfull"
         # IO.inspect :ets.lookup(:tweet, user)
         tweets = get_user_tweets(user)
          if length( tweets ) > 0 do
            GenServer.cast(pid ,{:receive_tweets, tweets })
          end
          
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

    defp initialize(_user) do
      # do all the intialization if tables are empty
    end

    ## Update "subscribed_by_users list"
    def handle_call({:subscribe_user, user, subscribe_to_user}, _from, state) do
      if user == subscribe_to_user do
        IO.puts "User #{user} can't subscribe himself"
      else
        subscribe_details = :ets.lookup(:subscribe, subscribe_to_user)
        if length(subscribe_details) == 0 do
          :ets.insert_new(:subscribe, {subscribe_to_user, [user]})
          #IO.inspect "User #{user} subscribed to User #{subscribe_to_user}"
        else
          [ {subscribe_to_user, subscribed_by_users} ] = subscribe_details
          if Enum.member?(subscribed_by_users, user) do
            IO.puts "User #{user} was already subscribed to User #{subscribe_to_user}"
          else
            subscribed_by_users = subscribed_by_users ++ [user]
            :ets.insert(:subscribe, {subscribe_to_user, subscribed_by_users})
            #IO.inspect "User #{user} subscribed to User #{subscribe_to_user}"
          end
        end
      end
      {:reply, "pass", state}
    end

    def handle_call({:tweet, user, tweet_text} ,_from, state) do
        # IO.puts (Enum.at(list,length(list) -1) - start_time)

        if String.length( tweet_text ) > 0 do
          #add tweet to thi user tweets
          index =  add_tweet(user,tweet_text)
          notify_subscribers(user , user , tweet_text ,index)
          {:reply, "pass", state}
        else
          {:reply, "fail", state}
        end
        
    end

    
    
     # change pid to gproc, as pid can change, if supervisor restarts user process
     def handle_call({:logout, user }, _from, state) do
      
      # existing_usres_map = :ets.lookup(:user_lookup, "users")
      # user_details = Map.get( existing_usres_map , user) 
      user_details = :ets.lookup(:user, user)
      if length(user_details) > 0 do
        # user exists and password matches
        # update the map to have loginflag as 1
        # existing_usres_map = %{ existing_usres_map | user => [password,1] }
        [ {user, stored_password, _ , pid} ] = user_details
        
          :ets.insert(:user, {user, stored_password, 0, pid})
          ## add pending login functionality here 
          {:reply, "pass", state}
        else
          IO.puts "Please try again"
          {:reply, "fail", state}
        
      end
    
    end

    #for delete the users from registered list, but will preserve the user tweets
    def handle_call({ :delete , user },_from,state) do
      # IO.puts (Enum.at(list,length(list) -1 ) - start_time)
      :ets.delete(:user, user)
      user_details = :ets.lookup(:user, user)
      
      if length(user_details) == 0 do
        {:reply, "pass", state}
      else
        {:reply, "fail", state}
      end

      
  end  

   #for searching , when user is not looged in
   def handle_call({ :search_by_hashtag , hashtag },_from,state) do
    # IO.puts (Enum.at(list,length(list) -1 ) - start_time)
    
    tweets_with_hashtag = :ets.lookup(:hashtag, hashtag)
    
    if length(tweets_with_hashtag) == 0 do
      {:reply, [], state}
    else
      [ {_hashtag, tweets} ] = tweets_with_hashtag
      {:reply, tweets, state}
    end

    
  end 
  
   #for searching , when user is not looged in
   def handle_call({ :search_by_user , user },_from,state) do
    # IO.puts (Enum.at(list,length(list) -1 ) - start_time)
    
   # get_user_tweets(user) ++ get_mention_tweets(user)
    {:reply, get_user_tweets(user) ++ get_mention_tweets(user), state}

  end 
  
  
    def handle_call(:get,_from,state) do
        # IO.puts (Enum.at(list,length(list) -1 ) - start_time)
        {:reply, state, state}
    end 
    
     

    #will return the list of tweets in which user is mentioned
    defp get_mention_tweets(user) do
      
      user_mentions = :ets.lookup(:mention, user)

      if length(user_mentions) == 0 do
        []
      else
        [ {_user, mention_tweets} ]= user_mentions
        mention_tweets
      end

    end

    #will return list of user tweets / if empty return the empty ;=list
    defp get_user_tweets(user) do
      
      user_tweets = :ets.lookup(:tweet, user)

      if length(user_tweets) == 0 do
        []
      else
        [ {_user,tweets} ] = user_tweets
        tweets
      end

    end

    #get this user tweet at particulat index
    defp get_user_tweet_at_index( user , index) do
      
      user_tweets = :ets.lookup(:tweet, user)

      if length(user_tweets) == 0 do
        ""
      else
        [ {_user,tweets} ] = user_tweets
        if length(tweets) <= index do
          ""
        else
          Enum.at(tweets , index )
        end
      end
    end

    defp add_tweet(user, tweet) do
      user_tweets = :ets.lookup(:tweet, user)

      if length(user_tweets) > 0 do
        [ {user, tweets} ] = user_tweets
        tweets = tweets ++ [tweet]
        :ets.insert(:tweet, {user , tweets} ) 
      else
        :ets.insert_new(:tweet, {user, [tweet]}) 
      end

      check_for_hashtag(user, tweet)
      user_tweets = :ets.lookup(:tweet, user)
      [ {_user, tweets} ] = user_tweets
      length(tweets) - 1
    end

    defp add_retweet( user, tweet_owner, tweet_index) do
      
      retweets = get_retweet(user)

      if length( retweets ) > 0 do
        retweets = retweets ++ [[tweet_owner,tweet_index]]
        :ets.insert(:retweet, {user, retweets} ) 

      else  
        :ets.insert_new(:retweet, {user, [ [tweet_owner , tweet_index] ]} ) 
      end

      

    end

    defp get_retweet( user) do
      user_retweets = :ets.lookup(:retweet, user)

      if length(user_retweets) == 0 do
        []
      else
        [ {_user,retweets} ] = user_retweets
        retweets
      end
    end

    defp add_tweet_with_hashtag(_user, tweet, hashtag) do
      hashtag_tweets = :ets.lookup(:hashtag, hashtag)
      #IO.puts "Debug add_tweet_with_hashtag"
      #IO.inspect hashtag_tweets
      if length(hashtag_tweets) > 0 do
        [ {hashtag, tweets} ] = hashtag_tweets
        tweets = tweets ++ [tweet]
        :ets.insert(:hashtag, {hashtag, tweets} ) 
      end
    end

    defp check_for_hashtag(user,tweet) do
      hashtags = Regex.scan(~r/#([a-zA-z0-9]*)/,tweet)
      #IO.puts "Debug check_for_hashtag" 
      #IO.puts tweet
      #IO.inspect hashtags
      if length(hashtags) > 0 do
        Enum.each( hashtags, fn [hashtag,_] -> 
          add_tweet_with_hashtag(user, tweet , hashtag)
        end )
      
      end
    end

end
