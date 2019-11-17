defmodule MySupervisor do
  @moduledoc """
  This module acts as the supervisor. It creates the children and assigns them to the supervisor.
  """
  use Supervisor

  def start_link(init_arg) do 
    Supervisor.start_link(__MODULE__,init_arg)
  end

  # arg1: numNodes, arg2: numRequest
  def init([arg1, arg2]) do
    
    children = Enum.map(1..arg1, fn(n) ->

     
        worker(Client, [Generic.generate_id( Integer.to_string(n) ) ], [id: Generic.generate_id( Integer.to_string(n) ), restart: :transient, shutdown: :infinity])
      

    end)

    children =  [worker(Server , [arg1, arg2] , [id: Server, restart: :transient, shutdown: :infinity])] ++ children

    #children = children ++ [worker(NodeInfo , [] , [id: NodeInfo, restart: :transient, shutdown: :infinity])]

    supervise(children, strategy: :one_for_one)
  
  end

end