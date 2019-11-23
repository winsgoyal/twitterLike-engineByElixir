defmodule Client  do 
  use GenServer
  
  def start_link(n) do
     GenServer.start_link(__MODULE__, %{routing_table: [],nodeid: "", backpointers: %{}},name: String.to_atom(n) )
    
    # get_in(users, ["john", :age])
    # put_in(users.obj["2344"],["a"])
  
  end
  
  def init(state) do

    # this user tweets
    :ets.new(:tweet, [:set, :protected, :named_table])

     # this user notifications
    :ets.new(:notification, [:set, :protected, :named_table])

    # this user mentions
    :ets.new(:mention, [:set, :protected, :named_table])

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
    GenServer.cast(pid, {:subscribe_to, user, subscribe_to_user})
  end

 
  # this function will receive tweets from server upon login (mostly) and set the user tweets table
  def receive_tweets(pid , tweets)  do
    GenServer.cast(pid, {:receive_tweets, tweets})
  end
  
  def set_state(pid, nodeid, routing_table) do  
    GenServer.cast(pid, {:set_state,routing_table,nodeid})
  end
  
  


   #it will receive notification and store the tweets in notification
   # if user is mentioned than stored in mentioned table
   def handle_cast({:notification, tweet , message } , state ) do
    IO.puts "Notification" <> message
    if String.contains?(tweet, "@" ) do
      :ets.insert_new(:mention, {user, tweets ++ [tweet] })
    else
      :ets.insert_new(:notification, {user, tweets ++ [tweet] })
    end
    
    {:noreply, state }    
  end

  

  #initialize user tweets, if any received from server
  def handle_cast({:receive_tweets, tweets} , state ) do

     :ets.insert_new(:tweet, { user, tweets })
     {:noreply, state }    
  end


  def handle_call( {:tweet, user , tweet }  , state) do
    
    {:reply, result, state} = TwitterServer.tweet( user , tweet )
    if result == "pass" do
      tweets = :ets.lookup(:subscribe, user)
      :ets.insert_new(:tweet, {user, tweets ++ [tweet] })
    else
      IO.puts "Wither tweet is empty or please try again"
    end
    {:reply, state, state, :infinity}  
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state, :infinity}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state, :infinity}
  end
  
  def handle_call({:register, user, password}, _from, state) do
    TwitterServer.register( user , password ) ;
    {:reply,state, state , :infinity}
  end

  def handle_call({:login, user, password}, _from, state) do
    {:reply, result, state} = TwitterServer.login( user, password , self() )

    if result == "pass" do
      :ets.insert_new(:tweet, {user, []})
      :ets.insert_new(:notification, {user, []})
    else
      IO.puts "Login Failed, Please check Credentials"
    end

    {:reply, state, state, :infinity}
  end

  def handle_cast ({:subscribe_to, user, subscribe_to_user}, _from, state) do
    TwitterServer.subscribe_user(user, subscribe_to_user)
    {:noreply, state }
  end
  
  def handle_call(:set, _from, state) do
    {:reply, state, [], :infinity}
  end
   
end
