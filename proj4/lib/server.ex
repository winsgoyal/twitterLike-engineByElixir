defmodule Server do 
    use GenServer

    def start_link(numNodes,numRequests) do
        GenServer.start_link(__MODULE__, {numNodes*numRequests,0},name: __MODULE__ )
    end
    def init(state) do
       {:ok, state}
    end

    def get() do  
        GenServer.call(__MODULE__, :get, :infinity)
      end

    def register(user) do
      GenServer.cast(__MODULE__, {:register,user})
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
    def initiate_requests(numNodes, numRequests) do
        
        Enum.each(1..numNodes, fn n ->
            nodeid = Generic.generate_id(Integer.to_string(n))
            pid = Process.whereis(String.to_existing_atom(nodeid ))

            Tapestry.send_to_nodes( pid , numNodes , numRequests )
          end
            )
        
    end

    #Tapsetry nodes will use this function to send done requests
    #to Server, and will send the  counts of hops for routing to a node
    def done(hop_count) do
       GenServer.cast(__MODULE__, {:done,hop_count})
    end

  
   
    def handle_cast({:done,hop_count},{remaining_requests, maxhop_count}) do
        # Reduce the request count on receivind done message and also updae the max_hop if necessry
       {:noreply, {remaining_requests - 1 , find_max(maxhop_count, hop_count)} }
    end


    
    def handle_call(:get,_from,state) do
        #IO.puts (Enum.at(list,length(list) -1 ) - start_time)
        {:reply, state,state}
    end

   def find_max(n1,n2) do
       if n1 > n2 do
           n1
       else
           n2
       end
   end



end