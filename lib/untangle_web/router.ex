defmodule UntangleWeb.Router do
  use UntangleWeb, :router

  scope "/", UntangleWeb do
    get("/modules", ModuleController, :index)
    get("/modules/:identifier", ModuleController, :show)
  end
end
