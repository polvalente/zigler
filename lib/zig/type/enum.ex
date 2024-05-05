defmodule Zig.Type.Enum do
  alias Zig.Type
  use Type

  defstruct [:tags, :name]
  @type t :: %__MODULE__{tags: %{optional(atom) => String.t()}, name: String.t()}

  def from_json(%{"tags" => tags, "name" => name}, module) do
    %__MODULE__{
      tags: Map.new(tags, fn {key, val} -> {String.to_atom(key), val} end),
      name: String.trim_leading(name, ".#{module}.")
    }
  end

  def inspect(enum, opts) do
    ~s(%Zig.Type.Enum{name: "#{enum.name}", tags: #{Kernel.inspect(enum.tags, opts)}})
  end

  def param_allowed?(_), do: true
  def return_allowed?(_), do: true
  def can_cleanup?(_), do: false

  def marshal_param(_, _, _, _), do: Type._default_marshal()
  def marshal_return(_, _, _), do: Type._default_marshal()
  def render_payload_options(_, _, _), do: Type._default_payload_options()
  def render_return(_, _), do: Type._default_return()

  def render_elixir_spec(%{tags: tags}, _, _opts) do
    tags
    |> Map.keys()
    |> Enum.sort()
    |> Enum.reverse()
    |> Enum.reduce(fn a, b ->
      quote do
        unquote(a) | unquote(b)
      end
    end)
  end
end
