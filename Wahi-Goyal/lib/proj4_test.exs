defmodule Proj4.TwitterEngineTest do
  
  use ExUnit.Case, async: false
  doctest Proj4.TwitterEngine

  
  def start_processes(args) do
    {:ok, supervisor} = MySupervisor.start_link(args)
    Enum.map( 1..Enum.at(args, 0), fn user -> Process.whereis(String.to_atom(Integer.to_string(user))) end )
  end

  def wait(pid ) when pid != nil do
    wait(pid)
  end
  # IF CLIENT PROCESSES WERE CREATED OR NOT
 # describe "Creating Clients" do
    test "create first user"  do
      IO.puts "Test 1"
      numUsers = 3
      numMsgs = 10
      pids = start_processes([numUsers, numMsgs])
  
      assert Process.info(Enum.at(pids, 0), :registered_name) == {:registered_name, :"1"}
      IO.puts "Success: User 1 was created\n"
      pid  = Process.whereis(:TwitterServer)
      IO.puts "hahahaha"
      IO.inspect pid
      wait(pid )
      Process.sleep(1000)
    end
  
    test "create large number of users"  do
      IO.puts "Test 2"
      numUsers = 1000
      numMsgs = 10
      pids = start_processes([numUsers, numMsgs])
      pid  = Process.whereis(:TwitterServer)
      IO.puts "hahahaha"
      IO.inspect pid
      pids = Enum.filter( pids, fn pid -> pid != nil end)
      assert length(pids) == numUsers
      IO.puts "Success: 1000  Users was created\n"
      pid  = Process.whereis(:TwitterServer)
      IO.puts "hahahaha"
      IO.inspect pid
      Process.sleep(1000)
      pid  = Process.whereis(:TwitterServer)
      IO.puts "hahahaha"
      IO.inspect pid
      wait(pid )
    end
  #end

  # IF TABLES AT SERVER SIDE WERE CREATED OR NOT
  #describe "Check whether Server's tables were created" do
    test "whether Subscribe table exists" do
      IO.puts "Test 3"
      numUsers = 3
      numMsgs = 10
      pids = start_processes([numUsers, numMsgs])
      refute :ets.whereis(:subscribe) == :undefined
      IO.puts "Success: Subscribe table exists\n"
      Process.sleep(1000)
      pid  = Process.whereis(:TwitterServer)
      IO.puts "hahahaha"
      IO.inspect pid
      wait(pid )
    end
  
    test "whether Hashtag table exists" do
      IO.puts "Test 4"
      numUsers = 3
      numMsgs = 10
      pids = start_processes([numUsers, numMsgs])
      refute :ets.whereis(:hashtag) == :undefined
      IO.puts "Success: Hashtag table exists\n"
      Process.sleep(1000)
    end
  #end
  
  # IF USER IS ABLE TO CREATE HIS ACCOUNT
  
    test "first user registers"  do
      IO.puts "Test 5"
      numUsers = 3
      numMsgs = 10
      pids = start_processes([numUsers, numMsgs])
      Client.register( Enum.at(pids, 0), "1", "user1" )
      assert :ets.lookup(:user, "1") == [{"1", "user1", 0, 0}]
      IO.puts "Success: User 1 registered, currently logged out\n"
      Process.sleep(1000)
    end

    test "two users register"  do
      IO.puts "Test 6"
      numUsers = 3
      numMsgs = 10
      pids = start_processes([numUsers, numMsgs])
      Client.register( Enum.at(pids, 1), "2", "user2" )
      Client.register( Enum.at(pids, 2), "3", "user3" )
      assert :ets.lookup(:user, "2") == [{"2", "user2", 0, 0}]
      assert :ets.lookup(:user, "3") == [{"3", "user3", 0, 0}]
      IO.puts "Success: Both users registered successfully, currently logged out\n"
      Process.sleep(1000)
    end

    test "can't create duplicate user"  do
      IO.puts "Test 7"
      numUsers = 3
      numMsgs = 10
      pids = start_processes([numUsers, numMsgs])
      refute Client.register( Enum.at(pids, 1), "2", "user2" ) == "fail"
      IO.puts "Success: User can't create same account twice\n"
      Process.sleep(1000)
    end
  

  # GET THE USER TO LOGIN AND MAINTAIN ONLINE STATUS
  #describe "test if the Login/Logout works" do
    test "username is incorrect during login"  do
      IO.puts "Test 8"
      numUsers = 3
      numMsgs = 10
      pids = start_processes([numUsers, numMsgs])
      refute Client.login( Enum.at(pids, 1), "5", "user5" ) == "fail"
      IO.puts "Sucess: The user doesn't exist\n"
      Process.sleep(1000)
    end

    test "password is incorrect during login"  do
      IO.puts "Test 9"
      numUsers = 3
      numMsgs = 10
      pids = start_processes([numUsers, numMsgs])
      refute Client.login( Enum.at(pids, 1), "2", "user5" ) == "fail"
      IO.puts "Success: Incorrect password\n"
      Process.sleep(1000)
    end

    test "one user logs-in"  do
      IO.puts "Test 10"
      numUsers = 3
      numMsgs = 10
      pids = start_processes([numUsers, numMsgs])
      Client.register( Enum.at(pids, 0), "1", "user1" )
      Client.login( Enum.at(pids, 0), "1", "user1" )
      [{_, _, status, _}] = :ets.lookup(:user, "1")
      assert status == 1
      IO.puts "Success: User is logged in now\n"
      Process.sleep(1000)
    end

    test "one user logs-out"  do
      IO.puts "Test 11"
      numUsers = 3
      numMsgs = 10
      pids = start_processes([numUsers, numMsgs])

      IO.puts "Step1: Register User 1"
      Client.register( Enum.at(pids, 0), "1", "user1" )
      IO.puts "Step2: Register User 1"
      Client.login( Enum.at(pids, 0), "1", "user1" )
      IO.puts "Step3: Register User 1"
      Client.logout( Enum.at(pids, 0), "1" )
      [{_, _, status, _}] = :ets.lookup(:user, "1")
      assert status == 0
      IO.puts "Success: Logged out\n"
      Process.sleep(1000)
    end



    test "other/all users login"  do
      IO.puts "Test 12"
      numUsers = 3
      numMsgs = 10
      pids = start_processes([numUsers, numMsgs])
      list = Enum.to_list(1..numUsers )
      Enum.each( list, fn user -> 
        IO.puts "Registering User " <> Integer.to_string(user)
        pid = Process.whereis( String.to_atom(Integer.to_string(user)) )   
        Client.register( pid, Integer.to_string(user), "user" <> Integer.to_string(user) )  
      end )

      Enum.each( list, fn user -> 
        IO.puts "Login User " <> Integer.to_string(user)
        pid = Process.whereis( String.to_atom(Integer.to_string(user)) )
        Client.login( pid, Integer.to_string(user), "user" <> Integer.to_string(user) )
      end )
      
      assert Enum.map( ["1", "2", "3"], fn username -> elem(Enum.at(:ets.lookup(:user, username), 0), 2) end ) == [1, 1, 1]
      IO.puts "Success: Three users logged-in\n"
      Process.sleep(1000)
    end
  end

#   describe "Tweeting Starts" do
#     test "User tweets a tweet", do
#       IO.puts "Test 13"
#       numUsers = 3
#       numMsgs = 10
#       pids = start_processes([numUsers, numMsgs])
#       list = Enum.to_list(1..numUsers )
#       Enum.each( list, fn user -> 
#         IO.puts "Registering User " <> Integer.to_string(user)
#         pid = Process.whereis( String.to_atom(Integer.to_string(user)) )   
#         Client.register( pid, Integer.to_string(user), "user" <> Integer.to_string(user) )  
#       end )

#       Enum.each( list, fn user -> 
#         IO.puts "Login User " <> Integer.to_string(user)
#         pid = Process.whereis( String.to_atom(Integer.to_string(user)) )
#         Client.login( pid, Integer.to_string(user), "user" <> Integer.to_string(user) )
#       end )
      
#       Enum.each( list, fn user -> 
#         user = Integer.to_string(user) 
#         [ {user, _, login_flag, pid} ] = :ets.lookup(:user, user)
#         IO.puts "Verifying User " <> user " Login Success"
#         assert login_flag == 1

#       end)

#       Enum.each( list, fn user -> 
#         user = Integer.to_string(user)
#         pid = Process.whereis( String.to_atom(user) )
       
#         Client.tweet( pid, Integer.to_string(user), "user" <> user <> " Test tweet no "  )
#         IO.puts "Verifying tweet is added to the server ets"
#         assert TwitterServer.get_user_tweet_at_index( user , -1) == "user" <> user <> " Test tweet no "
        
#       end )
  
      
      
#     end
#   end
# end
# #     test "", do
# #       IO.puts "Test 14"

# #       IO.puts "Success: "
# #     end

# #     test "", do
# #       IO.puts "Test 15"

# #       IO.puts "Success: "
# #     end
# #   end

# #   describe "Subscribe User's Tweets" do
# #     test "", do
# #       IO.puts "Test 16"

# #       IO.puts "Success: "
# #     end

# #     test "", do
# #       IO.puts "Test 17"

# #       IO.puts "Success: "
# #     end

# #     test "", do
# #       IO.puts "Test 18"

# #       IO.puts "Success: "
# #     end
# #   end

# #   describe "Notifications to User when live" do
# #     test "", do
# #       IO.puts "Test 19"

# #       IO.puts "Success: "
# #     end

# #     test "", do
# #       IO.puts "Test 20"

# #       IO.puts "Success: "
# #     end

# #     test "", do
# #       IO.puts "Test 21"

# #       IO.puts "Success: "
# #     end
# #   end

# #   describe "Notifications to User when live after disconnect" do
# #     test "", do
# #       IO.puts "Test 22"

# #       IO.puts "Success: "
# #     end

# #     test "", do
# #       IO.puts "Test 23"

# #       IO.puts "Success: "
# #     end

# #     test "", do
# #       IO.puts "Test 24"

# #       IO.puts "Success: "
# #     end
# #   end

# #   describe "User searches for 'My Mentions'" do
# #     test "", do
# #       IO.puts "Test 25"

# #       IO.puts "Success: "
# #     end

# #     test "", do
# #       IO.puts "Test 26"

# #       IO.puts "Success: "
# #     end
# #   end

# #   describe "User searches for Other User" do
# #     test "", do
# #       IO.puts "Test 27"

# #       IO.puts "Success: "
# #     end

# #     test "", do
# #       IO.puts "Test 28"

# #       IO.puts "Success: "
# #     end
# #   end

# #   describe "Users retweet User's tweets" do
# #     test "", do
# #       IO.puts "Test 29"

# #       IO.puts "Success: "
# #     end

# #     test "", do
# #       IO.puts "Test 30"

# #       IO.puts "Success: "
# #     end

# #     test "", do
# #       IO.puts "Test 31"

# #       IO.puts "Success: "
# #     end

# #     test "", do
# #       IO.puts "Test 32"

# #       IO.puts "Success: "
# #     end
# #   end

  

# end
