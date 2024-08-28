defmodule Crazy8Web.Router do
  use Crazy8Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Crazy8Web.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Crazy8Web do
    pipe_through :browser

    get "/setup", EnsureSessionController, :index

    live_session :default do
      live "/", LobbyLive
      live "/game/:code", GameLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", Crazy8Web do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:crazy8, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: Crazy8Web.Telemetry
    end
  end
end
