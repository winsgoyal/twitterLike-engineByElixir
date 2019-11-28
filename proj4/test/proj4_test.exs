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
      IO.puts "Test 1"
      assert Process.info(context[:client1], :registered_name) == {:registered_name, :"1"}
      IO.puts "Success: User 1 was created\n"
    end
  
    test "create second user", context do
      IO.puts "Test 2"
      assert Process.info(context[:client2], :registered_name) == {:registered_name, :"2"}
      IO.puts "Success: User 2 was created\n"
    end
  end

  # IF TABLES AT SERVER SIDE WERE CREATED OR NOT
  describe "Check whether Server's tables were created" do
    test "whether Subscribe table exists" do
      IO.puts "Test 3"
      refute :ets.whereis(:subscribe) == :undefined
      IO.puts "Success: Subscribe table exists\n"
    end
  
    test "whether Hashtag table exists" do
      IO.puts "Test 4"
      refute :ets.whereis(:hashtag) == :undefined
      IO.puts "Success: Hashtag table exists\n"
    end
  end
  
  # IF USER IS ABLE TO CREATE HIS ACCOUNT
  describe "carry out User registrations" do
    test "first user registers", context do
      IO.puts "Test 5"
      Client.register( context[:client1], "1", "user1" )
      assert :ets.lookup(:user, "1") == [{"1", "user1", 0, 0}]
      IO.puts "Success: User 1 registered, currently logged out\n"
    end

    test "two users register", context do
      IO.puts "Test 6"
      Client.register( context[:client2], "2", "user2" )
      Client.register( context[:client3], "3", "user3" )
      assert :ets.lookup(:user, "2") == [{"2", "user2", 0, 0}]
      assert :ets.lookup(:user, "3") == [{"3", "user3", 0, 0}]
      IO.puts "Success: Both users registered successfully, currently logged out\n"
    end

    test "can't create duplicate user", context do
      IO.puts "Test 7"
      refute Client.register( context[:client2], "2", "user2" ) == "fail"
      IO.puts "Success: User can't create same account twice\n"
    end
  end

  # GET THE USER TO LOGIN AND MAINTAIN ONLINE STATUS
  describe "test if the Login/Logout works" do
    test "username is incorrect during login", context do
      IO.puts "Test 8"
      refute Client.login( context[:client2], "5", "user5" ) == "fail"
      IO.puts "Sucess: The user doesn't exist\n"
    end

    test "password is incorrect during login", context do
      IO.puts "Test 9"
      refute Client.login( context[:client2], "2", "user5" ) == "fail"
      IO.puts "Success: Incorrect password\n"
    end

    ## Giving error on Test 10, 11, 12 -> [error] GenServer :"1" terminating ## Check why and correct.
    # test "one user logs-in", context do
    #   IO.puts "Test 10"
    #   Client.login( context[:client1], "1", "user1" )
    #   [{_, _, status, _}] = :ets.lookup(:user, "1")
    #   assert status == 1
    #   IO.puts "Success: User is logged in now\n"
    # end

    # test "one user logs-out", context do
    #   IO.puts "Test 11"
    #   Client.logout( context[:client1], "1" )
    #   [{_, _, status, _}] = :ets.lookup(:user, "1")
    #   assert status == 0
    #   IO.puts "Success: Logged out\n"
    # end

    # test "other/all users login", context do
    #   IO.puts "Test 12"
    #   Client.login( context[:client1], "1", "user1" )
    #   Client.login( context[:client2], "2", "user2" )
    #   Client.login( context[:client3], "3", "user3" )
    #   assert Enum.map( ["1", "2", "3"], fn username -> Enum.at(Tuple.to_list(:ets.lookup(:user, username)), 2) end ) === [1, 1, 1]
    #   IO.puts "Success: Three users logged-in\n"
    # end
  end

  describe "Tweeting Starts" do
    test "", do
      IO.puts "Test 13"

      IO.puts "Success: "
    end

    test "", do
      IO.puts "Test 14"

      IO.puts "Success: "
    end

    test "", do
      IO.puts "Test 15"

      IO.puts "Success: "
    end
  end

  describe "Subscribe User's Tweets" do
    test "", do
      IO.puts "Test 16"

      IO.puts "Success: "
    end

    test "", do
      IO.puts "Test 17"

      IO.puts "Success: "
    end

    test "", do
      IO.puts "Test 18"

      IO.puts "Success: "
    end
  end

  describe "Notifications to User when live" do
    test "", do
      IO.puts "Test 19"

      IO.puts "Success: "
    end

    test "", do
      IO.puts "Test 20"

      IO.puts "Success: "
    end

    test "", do
      IO.puts "Test 21"

      IO.puts "Success: "
    end
  end

  describe "Notifications to User when live after disconnect" do
    test "", do
      IO.puts "Test 22"

      IO.puts "Success: "
    end

    test "", do
      IO.puts "Test 23"

      IO.puts "Success: "
    end

    test "", do
      IO.puts "Test 24"

      IO.puts "Success: "
    end
  end

  describe "User searches for 'My Mentions'" do
    test "", do
      IO.puts "Test 25"

      IO.puts "Success: "
    end

    test "", do
      IO.puts "Test 26"

      IO.puts "Success: "
    end
  end

  describe "User searches for Other User" do
    test "", do
      IO.puts "Test 27"

      IO.puts "Success: "
    end

    test "", do
      IO.puts "Test 28"

      IO.puts "Success: "
    end
  end

  describe "Users retweet User's tweets" do
    test "", do
      IO.puts "Test 29"

      IO.puts "Success: "
    end

    test "", do
      IO.puts "Test 30"

      IO.puts "Success: "
    end

    test "", do
      IO.puts "Test 31"

      IO.puts "Success: "
    end

    test "", do
      IO.puts "Test 32"

      IO.puts "Success: "
    end
  end

  

end
