defmodule Proj4.TwitterEngineTest do
  
  use ExUnit.Case, async: true
  doctest Proj4.TwitterEngine

  setup_all context do
    users = ["1", "2", "3"]
    # client_pids = Enum.map( users, fn user -> Client.start_link(user) )
    #               |> Enum.map( fn user -> Enum.at(Tuple.to_list(user), 1) )
    {:ok, pidC1} = Client.start_link("1") # Username: 'user1'
    {:ok, pidC2} = Client.start_link("2") # Username: 'user2'
    {:ok, pidC3} = Client.start_link("3") # Username: 'user3'
    {:ok, pidS} = TwitterServer.start_link()
    {:ok, [client1: pidC1, client2: pidC2, client3: pidC3, server: pidS]}
  end

  # IF CLIENT PROCESSES WERE CREATED OR NOT
  describe "Creating Clients" do
    test "create first user", context do
      assert Process.info(context[:client1], :registered_name) == {:registered_name, :"1"}
    end
  
    test "create second user", context do
      assert Process.info(context[:client2], :registered_name) == {:registered_name, :"2"}
    end
  end

  # IF TABLES AT SERVER SIDE WERE CREATED OR NOT
  describe "Check whether Server's  tables were created" do
    test "whether Subscribes table exists" do
      refute :ets.whereis(:subscribe) == :undefined
    end
  
    test "whether Hashtags table exists" do
      refute :ets.whereis(:hashtag) == :undefined
    end
  end
  

end
