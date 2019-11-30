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
        IO.puts "Test 1"
        set_up(2)
        
        Client.register(:"1", "1", "user1" )

        assert :ets.tab2list(:user) |> length == 1
    end

    test "register multiple users" do
       
        IO.puts "Test 2"
        numUsers = 1000
        set_up(numUsers)
       
        # MySupervisor.start_link([1000, 5])
        Enum.each(1..numUsers, fn x -> Client.register(:"#{x}", "#{x}", "user#{x}" ) end)
        assert :ets.tab2list(:user) |> length == 1000
    end

    test "whether Subscribe table exists" do
        IO.puts "Test 3"
        numUsers = 3
        numMsgs = 10
        set_up(numUsers)
        refute :ets.whereis(:subscribe) == :undefined
        IO.puts "Success: Subscribe table exists\n"
      end

      test "whether Hashtag table exists" do
        IO.puts "Test 4"
        numUsers = 3
        numMsgs = 10
        set_up(numUsers)
        refute :ets.whereis(:hashtag) == :undefined
        IO.puts "Success: Hashtag table exists\n"
        
      end
    #end
    
    # IF USER IS ABLE TO CREATE HIS ACCOUNT
    
    test "can't create duplicate user"  do
        IO.puts "Test 7"
        numUsers = 3
        numMsgs = 10
        set_up( numUsers )
        Client.register( :"#{1}", "#{1}", "user#{1}" )
        
        assert Client.register( :"#{1}", "#{1}", "user#{1}" ) == "fail"
        IO.puts "Success: User can't create same account twice\n"
        Process.sleep(1000)
      end
    
  
    
end