defmodule Proj4Test do
    use ExUnit.Case

    def set_up(numClients) do
        
     
        if :ets.whereis(:notification) != :undefined do
            :ets.delete(:notification)
        end
        if :ets.whereis(:client_tweet) != :undefined do
            :ets.delete(:client_tweet)
        end

        :ets.new(:notification, [:set, :public, :named_table])
        # this user notifications
        :ets.new(:client_tweet, [:set, :public, :named_table])

        TwitterServer.start_link()
        Enum.each(1..numClients, fn n -> Client.start_link("#{n}") end)
    end

    def get_tweets_length_notification(user) do
        user_notification = :ets.lookup(:notification, user)
    
        if length(user_notification) == 0 do
          0
        else
          [ {_user,tweets} ] = user_notification
          length(tweets)
          end
          
          
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
        IO.puts "======================= Test 15 ==========================="
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
        IO.puts "======================= Test 16 ==========================="
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
      IO.puts "======================= Test 17 ==========================="
      numUsers = 2
      set_up(numUsers)
      Client.subscribe_to(:"#{1}", "#{1}", "#{2}")
      Client.subscribe_to(:"#{2}", "#{2}", "#{1}")
      Client.subscribe_to(:"#{1}", "#{1}", "#{2}")
      refute :ets.lookup( :subscribe, "2" ) == [{"2", ["1", "1"]}]
      IO.puts "Success: User is already subscribed to that user"
      IO.puts "===========================================================\n"
    end

    test "Subscription and notifications"  do
        IO.puts "Test 17"
        numUsers = 10
        numTweets = 1
        user_list = Enum.to_list(1..numUsers)
        set_up( numUsers )

        
        IO.puts "Login and Registration"
        Enum.each(1..numUsers , fn user -> 
            result = Client.register( :"#{user}", "#{user}", "user#{user}" )
            assert result == "pass"
    
            assert Client.login( :"#{user}", "#{user}", "user#{user}" ) == "pass"
            IO.puts "Success: User is logged in now\n"

        
    end)

    IO.puts "********Subscriptions***********"
  
    numUsers = numUsers - 1 
    user_list = Enum.to_list(1..numUsers)
    

Enum.each( user_list, fn user -> 

    subscirbe_to_user = user + 1
    pid = Process.whereis( String.to_atom(Integer.to_string(user)) )
   
    assert Client.subscribe_to( pid, Integer.to_string(user), Integer.to_string(subscirbe_to_user) ) == "pass"
    
end)
    IO.puts "******** Tweets ***********"
    
    Enum.each(user_list , fn user -> 
     
        #notification length of its subscribers
        notification_length = get_tweets_length_notification( Integer.to_string(user + 1)  )
        Enum.each(1..numTweets , fn tweet_number ->
        assert Client.tweet( :"#{user}", Integer.to_string(user), "user" <> Integer.to_string(user) <> " tweet no. " <> Integer.to_string(tweet_number) ) == "pass"
        Process.sleep(1000)
        IO.puts "******** Verifying Notification is received **********"
        assert get_tweets_length_notification( Integer.to_string(user + 1)  ) == notification_length
    end)

   

   
   

end)



   

    #IO.inspect "Debug subscribe loop " <> user
    
 


  
       
      end


      test "Logout 1 User"  do
        IO.puts "Test 18"
        numUsers = 1
        numTweets = 1
        set_up( numUsers )

        

        Enum.each(1..numUsers , fn user -> 
            result = Client.register( :"#{user}", "#{user}", "user#{user}" )
            assert result == "pass"
    
            assert Client.login( :"#{user}", "#{user}", "user#{user}" ) == "pass"
            IO.puts "Success: User is logged in now\n"

            assert Client.logout( :"#{user}", "#{user}" ) == "pass"
           
    end)
       
      end
    

      test "Logout 1000 User"  do
        IO.puts "Test 9"
        numUsers = 1000
        numTweets = 1
        set_up( numUsers )


        Enum.each(1..numUsers , fn user -> 
            result = Client.register( :"#{user}", "#{user}", "user#{user}" )
            assert result == "pass"
    
            assert Client.login( :"#{user}", "#{user}", "user#{user}" ) == "pass"
            IO.puts "Success: User is logged in now\n"

            assert Client.logout( :"#{user}", "#{user}" ) == "pass"
           
    end)
       
      end


     
    

      test "Query by user/mention"  do
        IO.puts "Test 20"
        numUsers = 1000
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

            assert Client.logout( :"#{user}", "#{user}" ) == "pass"
           
    end)

    Enum.each(1..numUsers , fn user -> 
        
        assert length(Client.search( :"#{user}", "#{user}" )) > 0
       
end)

IO.puts "Search Successfull"


       
      end

      test "Query by hashtag"  do
        IO.puts "Test 21"
        numUsers = 1000
        numTweets = 1
        set_up( numUsers )

        

        Enum.each(1..numUsers , fn user -> 
            result = Client.register( :"#{user}", "#{user}", "user#{user}" )
            assert result == "pass"
    
            assert Client.login( :"#{user}", "#{user}", "user#{user}" ) == "pass"
            IO.puts "Success: User is logged in now\n"

            Enum.each(1..numTweets , fn tweet_number ->
                            assert Client.tweet( :"#{user}", Integer.to_string(user), "#focus user" <> Integer.to_string(user) <> " tweet no. " <> Integer.to_string(tweet_number) ) == "pass"
                        end) 

            assert Client.logout( :"#{user}", "#{user}" ) == "pass"
           
    end)

    Enum.each(1..numUsers , fn user -> 
        
        assert length(Client.search( :"#{user}", "#focus" )) > 0
       
end)

IO.puts "Search Successfull"


       
      end


      test "Deactivate User"  do
        IO.puts "Test 22"
        numUsers = 1000
        numTweets = 1
        set_up( numUsers )

        

        Enum.each(1..numUsers , fn user -> 
            result = Client.register( :"#{user}", "#{user}", "user#{user}" )
            assert result == "pass"
    
            assert Client.login( :"#{user}", "#{user}", "user#{user}" ) == "pass"
            IO.puts "Success: User is logged in now\n"

           

            assert Client.logout( :"#{user}", "#{user}" ) == "pass"

            assert Client.deactivate( :"#{user}", "#{user}" ) == "pass"
           
    end)

   
       


IO.puts "Search Successfull"


       
      end


      test "Zipf Subscription distribution"  do
        IO.puts "Test Bonus"
        numUsers = 10
        numTweets = 1
        maxSubscribers = 7
        user_list = Enum.to_list(1..numUsers)
        set_up( numUsers )

        
        IO.puts "Login and Registration"
        Enum.each(1..numUsers , fn user -> 
            result = Client.register( :"#{user}", "#{user}", "user#{user}" )
            assert result == "pass"
    
            assert Client.login( :"#{user}", "#{user}", "user#{user}" ) == "pass"
            IO.puts "Success: User is logged in now\n"

        
    end)

    IO.puts "********Subscriptions***********"
  
    #numUsers = numUsers - 1 
    user_list = Enum.to_list(1..numUsers)
    

Enum.each( user_list, fn user -> 

   random_users = Enum.take(user_list -- [user], Kernel.trunc(maxSubscribers/user) + 1 )
    
    #IO.inspect(random_users , label: "random up #{user}")
    pid = Process.whereis( String.to_atom(Integer.to_string(user)) )
    Enum.each(random_users, fn subscribe_to_user -> 
      Client.subscribe_to( pid, Integer.to_string(user), Integer.to_string(subscribe_to_user) )
    end )
    
end)
    IO.puts "******** Tweets ***********"
    
    notification_length_list = []

    notification_length_list = Enum.map(user_list , fn user ->  get_tweets_length_notification( Integer.to_string(user)  ) end)
    
    Enum.each(user_list , fn user -> 
     
        #notification length of its subscribers
       # notification_length = get_tweets_length_notification( Integer.to_string(user + 1)  )
        #IO.inspect(notification_length, label: "notification_length")
       # notification_length_list = notification_length_list ++ [notification_length]

        #IO.inspect(notification_length_list, label: "notification_length_list")
        #random_users = Enum.take(user_list -- [user], Kernel.trunc(maxSubscribers/user) + 1 )
        random_users = TwitterServer.get_subscribers(Integer.to_string(user))
        Enum.each(1..numTweets , fn tweet_number ->
        assert Client.tweet( :"#{user}", Integer.to_string(user), "user" <> Integer.to_string(user) <> " tweet no. " <> Integer.to_string(tweet_number) ) == "pass"
        Process.sleep(1000)
        # IO.inspect(random_users , label: "random down #{user}")
        Enum.each(random_users, fn subscribe -> 
           
            subscribe = String.to_integer(subscribe)
            # IO.inspect(notification_length_list)
            # IO.inspect(subscribe)
            notification_length = Enum.at(notification_length_list, subscribe - 1  )
            IO.puts "******** Verifying Notification is received for #{subscribe} **********"
            IO.puts "Received Notificaton for user #{subscribe}"
            IO.inspect Client.get_tweet_from_notification( Integer.to_string(subscribe), -1  )
            assert Client.get_tweet_from_notification( Integer.to_string(subscribe), -1  ) == "user" <> Integer.to_string(user) <> " tweet no. 1" 
        end)

    end)

   

   
   

end)



   

    #IO.inspect "Debug subscribe loop " <> user
    
 


  
       
      end



    end