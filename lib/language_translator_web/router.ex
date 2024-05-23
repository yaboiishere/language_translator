defmodule LanguageTranslatorWeb.Router do
  use LanguageTranslatorWeb, :router
  import LanguageTranslatorWeb.UserAuth

  alias LanguageTranslatorWeb.Plugs.{RequireAuth, RequireAdmin}

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LanguageTranslatorWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authorize do
    plug :require_authenticated_user
    # plug AuthorizationPlug
  end

  pipeline :no_auth do
    plug RequireAuth, :show
  end

  pipeline :require_auth do
    plug RequireAuth
  end

  pipeline :require_admin do
    plug RequireAdmin
  end

  # Other scopes may use custom stacks.
  # scope "/api", LanguageTranslatorWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:language_translator, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LanguageTranslatorWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", LanguageTranslatorWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{LanguageTranslatorWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", LanguageTranslatorWeb do
    pipe_through [:browser, :authorize]

    live_session :require_authenticated_user,
      on_mount: [{LanguageTranslatorWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
      live "/analysis/new", AnalysisLive.Index, :new
    end
  end

  scope "/", LanguageTranslatorWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{LanguageTranslatorWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  scope "/", LanguageTranslatorWeb do
    pipe_through :browser

    live "/", AnalysisLive.Index, :index
    live "/analysis", AnalysisLive.Index, :index
    live "/words/:word_id", WordLive.Show, :show
    live "/words", WordLive.Index, :index
    live "/languages", LanguageLive.Index, :index
  end

  scope "/", LanguageTranslatorWeb do
    pipe_through [:browser, :no_auth]
    live "/analysis/:id", AnalysisLive.Show, :show
  end

  scope "/", LanguageTranslatorWeb do
    pipe_through [:browser, :require_auth]
    live "/analysis/:id/edit", AnalysisLive.Index, :edit
    live "/analysis/:id/show/edit", AnalysisLive.Show, :edit
    live "/analysis/new", AnalysisLive.Index, :new
  end

  scope "/", LanguageTranslatorWeb do
    pipe_through [:browser, :require_admin]
    live "/users", UserLive.Index, :index
  end
end
