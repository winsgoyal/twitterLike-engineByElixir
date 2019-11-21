defmodule Proj3.Tapestry do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  #use Application
  #use Topologies
  import Supervisor, warn: false
  def main(args \\ []) do
    
    
    {_ ,[users, numRequests ],_} = OptionParser.parse(args ,  strict: [n: :integer, n: :integer])
    #case OptionParser.parse(System.argv() ,  strict: [n: :integer, k: String, o: String]) do
  
      #{_ ,[noOfNodes, topology , algorihm],_} -> divideArgAndCallFunc(String.to_integer(a),\\b))  ### For Nodes
      #{_ ,[a,b],_} -> app(String.to_integer(a),String.to_integer(b))
     # _ -> app(1,2)
      #end
      users = String.to_integer(users)
      {:ok, _pid} =   MySupervisor.start_link([users,numRequests])
      list = Enum.to_list(1..users )
      #Register each user
      Enum.each( list , fn user -> 
        pid = Process.whereis(String.to_atom(Integer.to_string(user)) )
       
        Client.register(pid , Integer.to_string(user) , "user" <> Integer.to_string(user) )
        
      end
        )

      #Login Each User
      Enum.each(1..users, fn user -> 
        pid = Process.whereis(String.to_atom(Integer.to_string(user ) ) )
        Client.login(pid , Integer.to_string(user) , "user" <> Integer.to_string(user) )
        
      end
        )

       
    end



  end

    
