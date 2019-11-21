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

      {:ok, state}
    end

    def get() do  
      GenServer.call(__MODULE__, :get, :infinity)
    end

    def register(user, password) do
      GenServer.call(__MODULE__, {:register,user, password})
    end

    def login(user , password) do
      GenServer.call(__MODULE__, {:login,user , password})
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
      GenServer.cast(__MODULE__, {:tweet,user, tweet_text })
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

    def handle_call({:register, user, password}, _from, state) do
      
      # existing_usres_map = :ets.lookup(:user, "users")
      # existing_usres_map = %{ existing_usres_map | user => [password, 0] }
      # existing_usres_map = Map.put(existing_usres_map, "a", 100)
      user_details = :ets.lookup(:user, user)
      if length(user_details) > 0 do
        IO.inspect "Username #{user} already exists"
      else
        :ets.insert_new(:user, {user, password, 0})
        IO.inspect "Username #{user} Created"
      end 

      {:reply, state, state}
    end

    def handle_call({:login, user, password}, _from, state) do
      
      # existing_usres_map = :ets.lookup(:user_lookup, "users")
      # user_details = Map.get( existing_usres_map , user) 
      user_details = :ets.lookup(:user, user)
      if length(user_details) >  0 do
        # user exists and password matches
        # update the map to have loginflag as 1
        # existing_usres_map = %{ existing_usres_map | user => [password,1] }
        [ {user, stored_password, _} ] = user_details
        if stored_password == password do
          :ets.insert_new(:user, {user, password, 0})
          IO.inspect "User #{user} Login Successfull"
        else
          IO.puts "User name/ password is not correct"
        end
      else
        IO.puts "User name/ password is not correct"
      end
      
      {:reply, state, state}
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

    def handle_call(:get,_from,state) do
        #IO.puts (Enum.at(list,length(list) -1 ) - start_time)
        {:reply, state, state}
    end

end
