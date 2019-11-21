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
  
  
  def set_objectds(pid , objectids) do  
    GenServer.cast(pid, {:set_state,objectids})
  end
  
  def send_to_nodes(pid , numNodes, numRequests
  ) do
    Enum.each(1..numRequests, fn _n -> 
      route_to_node( pid , Generic.generate_id(Integer.to_string(Enum.random(1..numNodes) )), 0 )
    end
      )
  end
  
  def route_to_node(pid, destination_nodeid, hop_count \\ 0) do
    GenServer.cast(pid, {:route_to_node,destination_nodeid , hop_count})
  end
  #serverid is the nodeid of node where the node is actually stored
  def publish_object(pid , objectid, serverid) do  
    GenServer.cast(pid, {:publish_object,objectid, serverid})
  end
  
  #to add neighbours to the existing list
  def handle_cast({:route_to_node,destination_nodeid, hop_count} ,%{routing_table: routing_list, nodeid: node_id } = state) do
  
    #IO.puts destination_nodeid
    #IO.puts node_id

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
  
  #to add neighbours to the existing list
  def handle_cast({:set_state,routing_table_value,node_id} ,%{routing_table: _list, nodeid: _} = state) do
  
    
    {:noreply,%{state | routing_table: routing_table_value , nodeid: node_id }  }
    
  end
  
  #to add neighbours to the existing list
  def handle_cast({:set_objectds, new_objectid_list} ,%{objectids: objectid_list} = state) do
  
    
    {:noreply,%{state | objectids: objectid_list ++ new_objectid_list}  }
    
  end
  
  #function to find the next hop and send message to continue the process
  #n : previous hop number, destination_node: node to be reached 
  def handle_cast({:next_hop, n, destination_nodeid, hop_count} ,%{routing_table: routing_list, nodeid: node_id} = state) do
  
    if node_id != destination_nodeid && n < 40 do
      nodeids = Enum.at(routing_list,n) #search in level n+1 for finding the next hop
      
      #find node matching with prefix upto n+1 lenght, as we have to match n+1th charater
      matched_node = Enum.filter(nodeids, fn nodeid -> String.starts_with?(nodeid, String.slice(destination_nodeid, 0..n)) end) 
      pid = Process.whereis(String.to_existing_atom((Enum.at(matched_node,0)) ))
      #IO.puts node_id
      #IO.puts "hahaha"
      GenServer.cast(pid, {:next_hop,n+1,destination_nodeid , hop_count + 1})
      {:noreply,state }
    else
      NodeInfo.done( hop_count + 1 )
      {:noreply,state }
    end
  
  end
  #to add neighbours to the existing list
  #def handle_cast({:publish_object,objectid, serverid} ,%{objectids: objectid_list} = state) do
  
    
   # {:noreply,%{state | objectids: objectid_list ++ objectid}  }
    
  #end

  def handle_call(:get, _from, state) do
    {:reply,state, state , 100000}
  end
  
  def handle_call({:register,user, password}, _from, state) do

    TwitterServer.register( user , password ) ;
    {:reply,state, state , 100000}
  end

  def handle_call({:login,user, password}, _from, state) do

    TwitterServer.login( user , password ) ;
    {:reply,state, state , 100000}
  end
  
  def handle_call(:set, _from, state) do
    {:reply,state, [] , 100000}
  end
  
  
  #find level for searching the next hop
  defp find_level(objectid,nodeid) do
    
    index = Enum.find_index(0..String.length(objectid), fn i -> String.at(objectid,i) != String.at(nodeid,i) end)
    #IO.puts "Index #{index}"
    if objectid == nodeid do
      40
    else
      index+1
    end
    
  
  end
  
 
  
    
    end