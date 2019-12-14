defmodule TwitterEngineWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do

    # Simulating 100 users first and in parallel
    numUsers = 100
    run_initial_users(numUsers)

    # List all child processes to be supervised
    children = [
      # Start the endpoint when the application starts
      TwitterEngineWeb.Endpoint
      # Starts a worker by calling: TwitterEngineWeb.Worker.start_link(arg)
      # {TwitterEngineWeb.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TwitterEngineWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def run_initial_users(numUsers) do
    IO.puts("Simulating 100 users, depends on numUsers value") 
    IO.puts("Each users posts maximum 5 tweets at random")

    users = Enum.map(1..numUsers, fn n -> "user_#{n}" end)
    Enum.each(users, fn x -> TwitterEngine.ServerInterface.register(x, x) end)

    Enum.each(users, fn x ->
      TwitterEngine.ServerInterface.tweet(x, random_tweet(numUsers))
    end)

    IO.puts("Initial Simulation completed.")
  end

  def random_tweet(numUsers) do
    random_user = Enum.random(Enum.map(1..numUsers, fn n -> "user_#{n}" end))
    random_hastag = Enum.random(Enum.map(1..10, fn n -> "hashtag_#{n}" end))

    "All IS Well! @#{random_user}, ##{random_hastag}."
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TwitterEngineWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
