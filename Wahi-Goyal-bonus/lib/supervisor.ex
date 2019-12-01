defmodule MySupervisor do
  @moduledoc """
  This module acts as the supervisor. It creates the children and assigns them to the supervisor.
  """
  use Supervisor

  def start_link(init_arg) do 
     # this user notifications
     :ets.new(:notification, [:set, :public, :named_table])
     
     # this user notifications
     :ets.new(:client_tweet, [:set, :public, :named_table])
    Supervisor.start_link(__MODULE__,init_arg)
  end

  # arg1: numUsers, arg2: numRequest
  def init([arg1, _arg2]) do
    
    children = Enum.map( 1..arg1, fn(n) ->
      
      worker( Client, [ Integer.to_string(n) ], [ id:  Integer.to_string(n) , restart: :transient, shutdown: :infinity ] )

    end )

    children = [worker(TwitterServer, [] , [id: TwitterServer, restart: :transient, shutdown: :infinity ])] ++ children

    supervise(children, strategy: :one_for_one)
  
  end

end
