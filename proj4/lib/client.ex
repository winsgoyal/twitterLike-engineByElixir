defmodule Client  do 
  use GenServer
  
  def start_link(n) do
     GenServer.start_link(__MODULE__, %{routing_table: [],nodeid: "", backpointers: %{}},name: String.to_atom(n) )
    
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
    GenServer.call(pid, {:register,user, password})
  end

  def login(pid, user, password) do
    GenServer.call(pid, {:login,user, password})
  end

  #User will tweet, this function then connect to server
  def tweet(pid, user) do
    GenServer.cast(pid, {:tweet,user})
  end

  # to receive tweet from servers
  def receive( ) do
     # code
  end
  
  def set_state(pid, nodeid, routing_table) do  
    GenServer.cast(pid, {:set_state,routing_table,nodeid})
  end
  
  #to add neighbours to the existing list
  def handle_cast({:route_to_node,destination_nodeid, hop_count} ,%{routing_table: routing_list, nodeid: node_id } = state) do
    level = find_level(destination_nodeid,node_id)
    if destination_nodeid == node_id do
      
      NodeInfo.done( hop_count + 1 )
    else
      if level == 1 do
        nodeids = Enum.at(routing_list,0) #search in level1
        matched_node = Enum.filter(nodeids, fn nodeid -> String.starts_with?(nodeid, String.at(destination_nodeid, 0)) end) 
        pid = Process.whereis(String.to_existing_atom((Enum.at(matched_node,0)) ))
       
        GenServer.cast(pid, {:next_hop,1,destination_nodeid, hop_count + 1})
      else
        nodeids = Enum.at(routing_list,1) #search in level2, if common
        matched_node = Enum.filter(nodeids, fn nodeid -> String.starts_with?(nodeid, String.at(destination_nodeid, 0)) end) 
        pid = Process.whereis(String.to_existing_atom((Enum.at(matched_node,0)) ))
        
        GenServer.cast(pid, {:next_hop,1,destination_nodeid, hop_count + 1})
      end 
    end

    {:noreply, state }    
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state, 100000}
  end
  
  def handle_call({:register,user, password}, _from, state) do
    TwitterServer.register( user , password ) ;
    {:reply,state, state , 100000}
  end

  def handle_call({:login, user, password}, _from, state) do
    TwitterServer.login( user, password ) ;
    {:reply, state, state, 100000}
  end
  
  def handle_call(:set, _from, state) do
    {:reply, state, [], 100000}
  end
   
end
