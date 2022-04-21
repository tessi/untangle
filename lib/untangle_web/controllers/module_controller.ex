defmodule UntangleWeb.ModuleController do
  use UntangleWeb, :controller

  # TODO: move the main logic into Untangle modules and remove them from the Web parts

  def index(conn, _params) do
    modules =
      :application.which_applications()
      |> Enum.flat_map(fn {app, _desc, _version} ->
        {:ok, modules} = :application.get_key(app, :modules)
        modules
      end)
      |> Enum.map(&fast_module_info/1)

    json(conn, modules)
  end

  def show(conn, %{"identifier" => identifier}) do
    with {:ok, module} <- to_module(identifier) do
      info =
        module
        |> fast_module_info()
        |> Map.merge(module_docs(module))
        |> Map.merge(ecto_graph(module))
        # I really, really want to get a list of caller/callee module identifiers for any module.
        # Too hard to get done right now, so leaving this empty.
        # Could be done using compilation tracers or inspecting the compiled BEAM files.
        # * https://hexdocs.pm/elixir/1.12/Code.html#module-compilation-tracers
        # * https://twitter.com/wilton_quinn/status/1517060793061154817
        |> Map.put(:callers, [])
        |> Map.put(:callees, [])

      json(conn, info)
    else
      error ->
        conn
        |> put_status(:not_found)
        |> json(error)
    end
  end

  defp to_module(identifier) do
    {:ok, String.to_existing_atom(identifier)}
  rescue
    _e ->
      ArgumentError
      {:error, :not_found}
  end

  defp fast_module_info(module) do
    Code.ensure_loaded!(module)

    identifier = to_string(module)

    {name, erlixir_module} =
      case identifier do
        "Elixir." <> name -> {name, true}
        name -> {name, false}
      end

    %{
      has_schema: function_exported?(module, :__schema__, 1),
      identifier: identifier,
      meta: %{
        erlixir_module: erlixir_module
      },
      name: name
    }
  end

  defp module_docs(module) do
    docs =
      case Code.fetch_docs(module) do
        {:docs_v1, _, _, _, %{"en" => docs}, _, _} -> docs
        _ -> nil
      end

    %{module_documentation: docs}
  end

  defp ecto_graph(module) do
    case Ecto.ERD.Graph.new([module], [:associations, :embeds]) do
      %{edges: edges, nodes: [%{fields: fields}]} ->
        %{
          schema: %{
            associations: Enum.map(edges, &serialize_ecto_edge(&1, module)),
            fields: Enum.map(fields, &serialize_ecto_field/1)
          }
        }

      _ ->
        %{}
    end
  end

  defp serialize_ecto_edge(edge, module) do
    type =
      case edge.assoc_types do
        [has: :one] -> :has_one
        [has: :many] -> :has_many
        [:belongs_to] -> :belongs_to
      end

    target =
      case edge do
        %{from: {_, ^module, _}, to: {_, target, _}} -> target
        %{from: {_, target, _}, to: {_, ^module, _}} -> target
      end

    %{
      type: type,
      identifier: to_string(target)
    }
  end

  defp serialize_ecto_field(%{name: name, primary?: is_primary, type: type}) do
    type = if type == :"Elixir.Ecto.UUID", do: :uuid, else: type

    %{
      name: name,
      is_primary: is_primary,
      type: type
    }
  end
end
