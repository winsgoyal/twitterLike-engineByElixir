defmodule Proj4.TwitterEngine do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  import Supervisor, warn: false
  def main(args \\ []) do
    
    { _, [users, numRequests], _ } = OptionParser.parse(args , strict: [n: :integer, n: :integer])

    users = String.to_integer(users)
    {:ok, _pid} =   MySupervisor.start_link([users,numRequests])
    list = Enum.to_list(1..users )
    
    # Register each user
    Enum.each( list, fn user -> 
      pid = Process.whereis( String.to_atom(Integer.to_string(user)) )   
      Client.register( pid, Integer.to_string(user), "user" <> Integer.to_string(user) )  
    end )

    #Login Each User
    Enum.each( 1..users, fn user -> 
      pid = Process.whereis( String.to_atom(Integer.to_string(user)) )
      Client.login( pid, Integer.to_string(user), "user" <> Integer.to_string(user) )
    end )

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

    




  end




end
