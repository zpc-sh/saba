defmodule Saba.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SabaWeb.Telemetry,
      Saba.Repo,
      {DNSCluster, query: Application.get_env(:saba, :dns_cluster_query) || :ignore},
      {Oban,
       AshOban.config(
         Application.fetch_env!(:saba, :ash_domains),
         Application.fetch_env!(:saba, Oban)
       )},
      {Phoenix.PubSub, name: Saba.PubSub},
      # Start a worker by calling: Saba.Worker.start_link(arg)
      # {Saba.Worker, arg},
      # Start to serve requests, typically the last entry
      SabaWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :saba]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Saba.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SabaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
