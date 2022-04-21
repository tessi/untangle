# Untangle

Helps you introspect your elixir modules.

**State of the Project**: This package is currently an experiment. The code is barely working, not tested and will likely change a lot while we experiment with it.

This package provides methods to introspect on modules used by your Elixir application.
It also offers a router that you can plug into your Phoenix app to get a (development) endpoint to enable
tooling to introspect into your modules.

We imagine this package to be the foundation of further dev tooling to make it easier to plan/navigate/introspect/communicate your elixir modules effectively.

## Installation

The package can be installed by adding `untangle` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:untangle, "~> 0.1.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/untangle](https://hexdocs.pm/untangle).

## Usage

docs TBD for non-phoenix projects.

If you are running a phoenix application, add the following to your `router.ex`:

```elixir
use MyAppWeb, :router
import Phoenix.LiveDashboard.Router

...

if Mix.env() == :dev do
  scope "/dev", as: :dev do
    forward("/explorer", UntangleWeb.Router)
  end
end
```

This will add two new endpoints:

* `GET /dev/explorer/modules` - returns a JSON array listing all modules used in your project
* `GET /dev/explorer/modules/:identifier` - returns JSON for a specific module, including callers, callees, and associations/fields if the module has an Ecto schema.
