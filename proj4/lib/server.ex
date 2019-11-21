defmodule TwitterServer do 
    use GenServer

    def start_link() do
        GenServer.start_link(__MODULE__, {0},name: __MODULE__ )
    end
    def init(state) do
       :ets.new(:user, [:set, :protected, :named_table])
       :ets.new(:tweets, [:set, :protected , :named_table])
       #:ets.new(:user, [:set, :protected , :named_table])
       #:ets.new(:user, [:set, :protected , :named_table])
       #:ets.new(:user, [:set, :protected , :named_table])
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

    #When user retweet some tweet, then that tweet will appear in
    #other users(subscriber) feed
    def re_tweet(user, tweet_id) do
      GenServer.cast(__MODULE__, {:re_tweet,user, tweet_id })
    end

    # user will subscribe to subscribe_to_user
    def subscribe( user, subscribe_to_user ) do
      GenServer.cast(__MODULE__, {:subscribe,user, subscribe_to_user })
    end
  
    

    #Tapsetry nodes will use this function to send done requests
    #to Server, and will send the  counts of hops for routing to a node
    def done(hop_count) do
       GenServer.cast(__MODULE__, {:done,hop_count})
    end

  
   
    def handle_cast({:done,_hop_count},state) do
        # Reduce the request count on receivind done message and also updae the max_hop if necessry
       #{:noreply, {remaining_requests - 1 , find_max(maxhop_count, hop_count)} }
       {:noreply, state }
    end

    def handle_call({:register, user, password}, _from, state) do
      # Reduce the request count on receivind done message and also updae the max_hop if necessry
      
      #existing_usres_map = :ets.lookup(:user, "users")
     # existing_usres_map = %{ existing_usres_map | user => [password, 0] }
      #existing_usres_map = Map.put(existing_usres_map, "a", 100)
      user_details = :ets.lookup(:user, user)
      if length(user_details) > 0 do
        IO.inspect "Username #{user} already exists"
      else
        :ets.insert_new(:user, {user, password, 0})
         IO.inspect "Username #{user} Created"
      end 
      
     
      {:reply, state,state}
    end

    def handle_call({:login, user, password}, _from, state) do
      # Reduce the request count on receivind done message and also updae the max_hop if necessry
      
      #existing_usres_map = :ets.lookup(:user_lookup, "users")
      #user_details = Map.get( existing_usres_map , user) 
      user_details = :ets.lookup(:user, user)
      if length( user_details) >  0 do
        #user exists and password matches
        #update the map to have loginflag as 1
        #existing_usres_map = %{ existing_usres_map | user => [password,1] }
        [ {user,stored_password, _} ]  = user_details
        if stored_password == password do
          :ets.insert_new(:user, {"users", {user, password, 1}})
           IO.inspect "User #{user} Login Successfull"
        else
          IO.puts "User name/ password is not correct"
        end
        
      else
        IO.puts "User name/ password is not correct"
      end
      
      {:reply, state, state}
    end


    
    def handle_call(:get,_from,state) do
        #IO.puts (Enum.at(list,length(list) -1 ) - start_time)
        {:reply, state,state}
    end




end