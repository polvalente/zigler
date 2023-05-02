defmodule ZiglerTest.Unit.Typespec.EgressTest do
  use ExUnit.Case, async: true

  @moduletag :typespec

  alias Zig.Type.Function
  import Zig.Type, only: :macros

  describe "when asking for a typespec return for basic types" do
    test "a void function gives a sane result" do
      result =
        quote context: Elixir do
          @spec egress() :: :ok
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: :void}) ==
               result
    end

    ###########################################################################
    ## INTS

    test "a u8-returning function gives appropriate bounds" do
      result =
        quote context: Elixir do
          @spec egress() :: 0..255
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t(u8)}) ==
               result
    end

    test "a u16-returning function gives appropriate bounds" do
      result =
        quote context: Elixir do
          @spec egress() :: 0..0xFFFF
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t(u16)}) ==
               result
    end

    test "a u32-returning function gives appropriate bounds" do
      result =
        quote context: Elixir do
          @spec egress() :: 0..0xFFFF_FFFF
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t(u32)}) ==
               result
    end

    test "a u64-returning function gives non_neg_integer" do
      result =
        quote context: Elixir do
          @spec egress() :: 0..0xFFFF_FFFF_FFFF_FFFF
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t(u64)}) ==
               result
    end

    test "an i32-returning function gives appropriate bounds" do
      result =
        quote context: Elixir do
          @spec egress() :: -0x8000_0000..0x7FFF_FFFF
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t(i32)}) ==
               result
    end

    test "an i64-returning function gives integer" do
      result =
        quote context: Elixir do
          @spec egress() :: -0x8000_0000_0000_0000..0x7FFF_FFFF_FFFF_FFFF
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t(i64)}) ==
               result
    end

    # we're not going to test c_int, c_uint, c_long, usize, etc. because these are not
    # testable across platforms in an easy way, and zig will do the platform-dependent
    # translations at compile time

    ###########################################################################
    ## FLOATS

    test "an f16-returning function gives float" do
      result =
        quote context: Elixir do
          @spec egress() :: float()
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t(f16)}) ==
               result
    end

    test "an f32-returning function gives float" do
      result =
        quote context: Elixir do
          @spec egress() :: float()
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t(f32)}) ==
               result
    end

    test "an f64-returning function gives float" do
      result =
        quote context: Elixir do
          @spec egress() :: float()
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t(f64)}) ==
               result
    end

    ###########################################################################
    ## BOOL

    test "a bool returning function is boolean" do
      alias Zig.Type.Bool

      result =
        quote context: Elixir do
          @spec egress() :: boolean()
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: %Bool{}}) ==
               result
    end

    ###########################################################################
    ## BEAM

    test "a beam.term returning function is term" do
      result =
        quote context: Elixir do
          @spec egress() :: term()
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: :term}) ==
               result
    end

    test "a e.ErlNifTerm returning function is term" do
      result =
        quote context: Elixir do
          @spec egress() :: term()
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: :erl_nif_term}) ==
               result
    end

    test "a beam.pid returning function is pid" do
      result =
        quote context: Elixir do
          @spec egress() :: pid()
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: :pid}) == result
    end

    test "an enum returning function is just the optional atoms" do
      result =
        quote context: Elixir do
          @spec egress() :: :error | :maybe | :ok
        end

      return = %Zig.Type.Enum{tags: %{ok: "ok", error: "error", maybe: "maybe"}}

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: return}) ==
               result
    end
  end

  describe "when asking for function returns for arraylike collections" do
    test "a u8-slice returning function is special and defaults to binary" do
      result =
        quote context: Elixir do
          @spec egress() :: binary()
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t([]u8)}) ==
               result
    end

    test "u8 can be forced to return list"

    test "a int-slice returning function is list of integer" do
      result =
        quote context: Elixir do
          @spec egress() :: [-0x8000_0000_0000_0000..0x7FFF_FFFF_FFFF_FFFF]
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t([]i64)}) ==
               result
    end

    test "int-slice can be forced to return binary"

    test "a float-slice returning function is list of float" do
      result =
        quote context: Elixir do
          @spec egress() :: [float()]
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t([]f64)}) ==
               result
    end

    test "float-slice can be forced to return binary"

    test "manypointer with sentinel u8 defaults to binary" do
      result =
        quote context: Elixir do
          @spec egress() :: binary()
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t([*:0]u8)}) ==
               result
    end

    test "manypointer with sentinel u8 can be charlist"

    test "array with u8 defaults to binary" do
      result =
        quote context: Elixir do
          @spec egress() :: <<_::80>>
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t([10]u8)}) ==
               result
    end

    test "array with u8 can be forced to return charlist"

    test "array with int defaults to list of integer" do
      result =
        quote context: Elixir do
          @spec egress() :: [0..0xFFFF_FFFF_FFFF_FFFF]
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t([10]u64)}) ==
               result
    end

    test "array with int can be forced to return binary"

    test "array with float defaults to list of float" do
      result =
        quote context: Elixir do
          @spec egress() :: [float()]
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t([10]f64)}) ==
               result
    end

    test "array with float can be forced to return binary"
  end

  describe "when asking for function returns for structs" do
    test "it returns a straight map" do
      result =
        quote context: Elixir do
          @spec egress() :: %{bar: binary(), foo: float()}
        end

      return = %Zig.Type.Struct{
        name: "Foo",
        required: %{foo: ~t(f64)},
        optional: %{bar: ~t([]u8)}
      }

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: return}) ==
               result
    end

    test "it returns binary if it's packed"
  end

  describe "when asking for optional returns" do
    test "it adds nil to the possible return" do
      result =
        quote context: Elixir do
          @spec egress() :: 0..255 | nil
        end

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: ~t(?u8)}) ==
               result
    end
  end

  describe "when asking for resource returns" do
    test "it marks it as a reference" do
      result =
        quote context: Elixir do
          @spec egress() :: reference()
        end

      return = %Zig.Type.Resource{}

      assert Function.spec(%Function{name: :egress, arity: 0, params: [], return: return}) ==
               result
    end

    test "it can know if the resource will emerge as a binary"
  end
end
