defmodule Proj4.TwitterEngine do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  import Supervisor, warn: false
  def main(args \\ []) do
    
    { _, [users, numTweets, maxSubscribers , percentageOfDisconnection], _ } = OptionParser.parse(args , strict: [n: :integer, n: :integer])

     # this user notifications
     #:ets.new(:notification, [:set, :public, :named_table])
     
     # this user notifications
     #:ets.new(:client_tweet, [:set, :public, :named_table])
     
    users = String.to_integer(users)
    numTweets = String.to_integer(numTweets)
    maxSubscribers = String.to_integer(maxSubscribers)
    percentageOfDisconnection = String.to_integer(percentageOfDisconnection)
    {:ok, _pid} =   MySupervisor.start_link([users,numTweets])
    list = Enum.to_list(1..users )
    
     # this user tweets
    # :ets.new(:tweet, [:set, :protected, :named_table])

    user_list = Enum.to_list(1..users) 

    # this user mentions
    #:ets.new(:mention, [:set, :protected, :named_table])

    IO.puts "********************************************************************"
    IO.puts "*************** Registration ********************"
    # Register each user
    Enum.each( list, fn user -> 
      pid = Process.whereis( String.to_atom(Integer.to_string(user)) )   
      Client.register( pid, Integer.to_string(user), "user" <> Integer.to_string(user) )  
    end )

    IO.puts "********************************************************************"

    IO.puts "*********************** Login ******************"
    #Login Each User
    Enum.each( 1..users, fn user -> 
      pid = Process.whereis( String.to_atom(Integer.to_string(user)) )
      Client.login( pid, Integer.to_string(user), "user" <> Integer.to_string(user) )
    end )

    Client.periodic_signin(user_list)
   
    IO.puts "********************************************************************"

    IO.puts "*********************** Tweet ******************"
    #Tweet from Each User
    Enum.each( 1..users, fn user -> 
      pid = Process.whereis( String.to_atom(Integer.to_string(user)) )
      Enum.each(1..numTweets , fn tweet_number ->
        Client.tweet( pid, Integer.to_string(user), "user" <> Integer.to_string(user) <> " tweet no. " <> Integer.to_string(tweet_number) )
      end)
      
    end )


    IO.puts "********************************************************************"

    IO.puts "*********************** Subscription ******************"
    #Subscribe Users
    Enum.each( 1..users, fn user -> 

      random_users = Enum.take_random(user_list -- [user], Kernel.trunc(maxSubscribers/user) + 1 )
      pid = Process.whereis( String.to_atom(Integer.to_string(user)) )
      Enum.each(random_users, fn subscribe_to_user -> 
        Client.subscribe_to( pid, Integer.to_string(user), Integer.to_string(subscribe_to_user) )
      end )
      #IO.inspect "Debug subscribe loop " <> user
      
    end )
    

   # pid = Process.whereis( String.to_atom(Integer.to_string(1)) )
   # Client.tweet( pid, Integer.to_string(1), "user" <> Integer.to_string(1) )

    :timer.sleep(1000);
    #IO.inspect :ets.lookup(:notification, "2")

    IO.puts "********************************************************************"

    IO.puts "*********************** Tweet with hash tag #focus ******************"
    pid = Process.whereis( String.to_atom(Integer.to_string(1)) )
    Client.tweet( pid, Integer.to_string(1), "#focus, everyday do something productive" <> Integer.to_string(1) )
    :timer.sleep(1000);
    #user 1 subscribing to user2
    #pid = Process.whereis( String.to_atom(Integer.to_string(1)) )
    #Client.subscribe_to( pid, "1", "2" )
    #IO.inspect :ets.lookup(:notification, "4")

    IO.puts "********************************************************************"

    IO.puts "*********************** Re-Tweet ******************" 
    #retweets
    Enum.each( 1..users, fn user -> 
      tweetinfo = Client.get_random_tweet_from_notification(Integer.to_string(user) )

      if length(tweetinfo) > 0 do
        #IO.puts "retweet " <> Integer.to_string(user)
        [tweet, tweet_owner, index ] = List.flatten(tweetinfo)
        pid = Process.whereis( String.to_atom(Integer.to_string(user))) 
      Client.retweet_tweet(pid , tweet , tweet_owner , index)
      end
      #IO.inspect "Debug subscribe loop " <> user
      
    end )

    IO.puts "********************************************************************"

    IO.puts "*********************** Logout ******************"
    #Logout Users
    Enum.each( 1..users, fn user -> 
      pid = Process.whereis( String.to_atom(Integer.to_string(user)) )
      #IO.inspect "Debug subscribe loop " <> user
      Client.logout( pid, Integer.to_string(user))
    end )


    IO.puts "********************************************************************"

    IO.puts "*********************** Search with hastag $focus ******************"
    #Search for tweet with hashtag #focus
    
    pid = Process.whereis( String.to_atom(Integer.to_string(2)) )
    #IO.inspect "Debug subscribe loop " <> user
    Client.search( pid, "#focus" )


    IO.puts "********************************************************************"

    IO.puts "*********************** Search with usernames ******************"
    #search for each users tweet
    #Logout Users
    Enum.each( 1..users, fn user -> 
      pid = Process.whereis( String.to_atom(Integer.to_string(user)) )
      #IO.inspect "Debug subscribe loop " <> user
      Client.search( pid, Integer.to_string(user))
    end )


    IO.puts "********************************************************************"

    IO.puts "*********************** Deactivation ******************"
    #search for each users tweet
    #Logout Users
    Enum.each( 1..users, fn user -> 
      pid = Process.whereis( String.to_atom(Integer.to_string(user)) )
      #IO.inspect "Debug subscribe loop " <> user
      Client.deactivate( pid, Integer.to_string(user))
    end )

    


    :timer.sleep(10000);


    ## Random selection between calling Function (i), i belongs to (1 .. n)
    ## Function 1
    ## Create some tweet formats, randomly choose one, every new tweet should be unique.
    ## E.g.
    ## Simple tweet -> No @User mentions, no hashtags 
    ## Tweet with one or multiple user mentions
    ## Tweet with one or multiple hashtag, choose some random hashtag from some list
    ## Tweet with user mentions and hashtags

    ## Add the live hashtags to a hashtag_list, so for the users to subscribe to.
    ## 
    ## Tweets in which the user in mentioned, is automatically subscribed (liked) by the user.
    ## 
    ## Every tweet can be liked by some random users.
    ## 

    ## Function 2
    ## User can re-tweet any tweet.
    ## 
    ## Function 3
    ## Users can subscribe to tweets.
    ##
    ## and so on.

    ## Implement Subscribe_to_user statement here.
    #############################################
    





  end




end
