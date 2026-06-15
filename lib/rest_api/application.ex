defmodule RestApi.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RestApiWeb.Telemetry,
      RestApi.Repo,
      {DNSCluster, query: Application.get_env(:rest_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RestApi.PubSub},
      # Start a worker by calling: RestApi.Worker.start_link(arg)
      # {RestApi.Worker, arg},
      # Start to serve requests, typically the last entry
      RestApiWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RestApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RestApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
