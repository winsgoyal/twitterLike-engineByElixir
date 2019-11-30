defmodule Proj4Test do
    use ExUnit.Case

    def set_up(numClients) do
        :ets.new(:notification, [:set, :public, :named_table])
     
        # this user notifications
        :ets.new(:client_tweet, [:set, :public, :named_table])

        TwitterServer.start_link()
        Enum.each(1..numClients, fn n -> Client.start_link("#{n}") end)
    end

    test "register user" do
        IO.puts "======================= Test 1 ==========================="
        set_up(2)
        
        Client.register(:"1", "1", "user1" )

        assert :ets.tab2list(:user) |> length == 1
        IO.puts "Success: First user got registered successfully\n"
        IO.puts "===========================================================\n"
    end

    test "register multiple users" do
        IO.puts "======================= Test 2 ==========================="
        numUsers = 1000
        set_up(numUsers)
      
        # MySupervisor.start_link([1000, 5])
        Enum.each(1..numUsers, fn x -> Client.register(:"#{x}", "#{x}", "user#{x}" ) end)
        assert :ets.tab2list(:user) |> length == 1000
        IO.puts "Success: All users got registered\n"
        IO.puts "===========================================================\n"
    end

    test "whether Subscribe table exists" do
        IO.puts "======================= Test 3 ==========================="
        numUsers = 3
        numMsgs = 10
        set_up(numUsers)
        refute :ets.whereis(:subscribe) == :undefined
        IO.puts "Success: Subscribe table exists\n"
        IO.puts "===========================================================\n"
    end

    test "whether Hashtag table exists" do
        IO.puts "======================= Test 4 ==========================="
        numUsers = 3
        numMsgs = 10
        set_up(numUsers)
        refute :ets.whereis(:hashtag) == :undefined
        IO.puts "Success: Hashtag table exists\n"
        IO.puts "===========================================================\n"
    end
    
    # IF USER IS ABLE TO CREATE HIS ACCOUNT
    test "can't create duplicate user"  do
        IO.puts "======================= Test 5 ==========================="
        numUsers = 3
        numMsgs = 10
        set_up( numUsers )
        Client.register( :"#{1}", "#{1}", "user#{1}" )
        
        assert Client.register( :"#{1}", "#{1}", "user#{1}" ) == "fail"
        IO.puts "Success: User can't create same account twice"
        IO.puts "===========================================================\n"
    end
    
    test "username is incorrect during login"  do
      IO.puts "Test 6"
      numUsers = 3
      
      set_up( numUsers )
      Client.register( :"#{1}", "#{1}", "user#{1}" )
      assert Client.register( :"#{1}", "#{1}", "user#{1}" ) == "fail"

      assert Client.login( :"#{1}", "#{9}", "user#{1}" ) == "fail"
      IO.puts "Sucess: The username or password wrong\n"
      Process.sleep(1000)
    end

    test "password is incorrect during login"  do
      IO.puts "Test 7"
      numUsers = 3
      set_up( numUsers )
      result = Client.register( :"#{1}", "#{1}", "user#{1}" )
      assert result == "pass"

      assert Client.login( :"#{1}", "#{1}", "user#{2}" ) == "fail"
      IO.puts "Success: Incorrect password\n"
      Process.sleep(1000)
    end

    test "one user logs-in"  do
      IO.puts "Test 8"
      numUsers = 3
      
      set_up( numUsers )
      result = Client.register( :"#{1}", "#{1}", "user#{1}" )
      assert result == "pass"

      assert Client.login( :"#{1}", "#{1}", "user#{1}" ) == "pass"
      IO.puts "Success: User is logged in now\n"
    
    end
  
    test "one user logs-out"  do
      IO.puts "Test 9"
      numUsers = 3
      
      
      set_up( numUsers )
      result = Client.register( :"#{1}", "#{1}", "user#{1}" )
      assert result == "pass"

      assert Client.login( :"#{1}", "#{1}", "user#{1}" ) == "pass"
      IO.puts "Success: User is logged in now\n"
      
      Client.logout( :"#{1}", "#{1}" )
      [{_, _, status, _}] = :ets.lookup(:user, "1")
      assert status == 0
      IO.puts "Success: Logged out\n"
      
    end

    test "100 users login"  do
      IO.puts "Test 12"
      numUsers = 100
      
      
      
      set_up( numUsers )

      Enum.each(1..numUsers , fn user -> 
          result = Client.register( :"#{user}", "#{user}", "user#{user}" )
          assert result == "pass"
  
          assert Client.login( :"#{user}", "#{user}", "user#{user}" ) == "pass"
          IO.puts "Success: User is logged in now\n"
      end) 
      
      IO.puts "Success: Three users logged-in\n"
      
    end

    test "1000 users login"  do
      IO.puts "Test 13"
      numUsers = 1000
      
      set_up( numUsers )

      Enum.each(1..numUsers , fn user -> 
          result = Client.register( :"#{user}", "#{user}", "user#{user}" )
          assert result == "pass"
  
          assert Client.login( :"#{user}", "#{user}", "user#{user}" ) == "pass"
          IO.puts "Success: User is logged in now\n"
      end) 
      
      
      
    end

    test "1 tweet for every  users"  do
      IO.puts "Test 14"
      numUsers = 10
      numTweets = 1
      set_up( numUsers )

      Enum.each(1..numUsers , fn user -> 
          result = Client.register( :"#{user}", "#{user}", "user#{user}" )
          assert result == "pass"
  
          assert Client.login( :"#{user}", "#{user}", "user#{user}" ) == "pass"
          IO.puts "Success: User is logged in now\n"

          Enum.each(1..numTweets , fn tweet_number ->
            assert Client.tweet( :"#{user}", Integer.to_string(user), "user" <> Integer.to_string(user) <> " tweet no. " <> Integer.to_string(tweet_number) ) == "pass"
          end) 
      end)
      
    end

    test "1 tweet with hashtag for every  users"  do
      IO.puts "Test 14"
      numUsers = 10
      numTweets = 1
      set_up( numUsers )

      Enum.each(1..numUsers-1 , fn user -> 
          result = Client.register( :"#{user}", "#{user}", "user#{user}" )
          assert result == "pass"
  
          assert Client.login( :"#{user}", "#{user}", "user#{user}" ) == "pass"
          IO.puts "Success: User is logged in now\n"

          Enum.each(1..numTweets , fn tweet_number ->
            assert Client.tweet( :"#{user}", Integer.to_string(user), " #focus user" <> Integer.to_string(user) <> " tweet no. " <> Integer.to_string(tweet_number) ) == "pass"
          end) 
      end)
      
    end

    test "1 tweet with mention for every  users"  do
      IO.puts "Test 14"
      numUsers = 10
      numTweets = 1
      set_up( numUsers )

      

      Enum.each(1..numUsers , fn user -> 
          result = Client.register( :"#{user}", "#{user}", "user#{user}" )
          assert result == "pass"
  
          assert Client.login( :"#{user}", "#{user}", "user#{user}" ) == "pass"
          IO.puts "Success: User is logged in now\n"

          Enum.each(1..numTweets , fn tweet_number ->
            assert Client.tweet( :"#{user}", Integer.to_string(user), "Mention @#{user+1} user " <> Integer.to_string(user) <> " tweet no. " <> Integer.to_string(tweet_number) ) == "pass"
          end) 
      end)
      
    end

    test "subscribe users" do
        IO.puts "======================= Test 6 ==========================="
        numUsers = 3
        set_up(numUsers)
        Client.subscribe_to(:"#{1}", "#{1}", "#{2}")
        Client.subscribe_to(:"#{2}", "#{2}", "#{3}")
        Client.subscribe_to(:"#{1}", "#{1}", "#{3}")
        Client.subscribe_to(:"#{2}", "#{2}", "#{1}")
        Client.subscribe_to(:"#{3}", "#{3}", "#{1}")
        Client.subscribe_to(:"#{3}", "#{3}", "#{2}")

        assert :ets.lookup( :subscribe, "1" ) == [{"1", ["2", "3"]}]
        assert :ets.lookup( :subscribe, "2" ) == [{"2", ["1", "3"]}]
        assert :ets.lookup( :subscribe, "3" ) == [{"3", ["2", "1"]}]
        IO.puts "Success: All subscriptions went successfully"
        IO.puts "===========================================================\n"
    end
    
    test "user tries to subscribe himself" do
        IO.puts "======================= Test 7 ==========================="
        numUsers = 2
        set_up(numUsers)
        Client.subscribe_to(:"#{1}", "#{1}", "#{2}")
        Client.subscribe_to(:"#{2}", "#{2}", "#{1}")
        Client.subscribe_to(:"#{2}", "#{2}", "#{2}")

        refute :ets.lookup( :subscribe, "2" ) == [{"2", ["1", "2"]}]
        IO.puts "Success: User can't subscribe himself"
        IO.puts "===========================================================\n"
    end

    test "user tries to subscribe other user again" do
      IO.puts "======================= Test 8 ==========================="
      numUsers = 2
      set_up(numUsers)
      Client.subscribe_to(:"#{1}", "#{1}", "#{2}")
      Client.subscribe_to(:"#{2}", "#{2}", "#{1}")
      Client.subscribe_to(:"#{1}", "#{1}", "#{2}")

      refute :ets.lookup( :subscribe, "2" ) == [{"2", ["1", "1"]}]
      IO.puts "Success: User is already subscribed to that user"
      IO.puts "===========================================================\n"
  end

    
end