defmodule FarmbotCeleryScript.MoveTest do
  use ExUnit.Case, async: false
  use Mimic

  alias FarmbotCeleryScript.{
    AST,
    Compiler,
    SysCalls.Stubs
  }

  alias FarmbotCeleryScript.SysCalls, warn: false

  setup :verify_on_exit!

  test "move" do
    move_block =
      "test/fixtures/move.json"
      |> File.read!()
      |> Jason.decode!()

    ast =
      %{
        kind: "sequence",
        args: %{
          locals: %{
            kind: "scope_declaration",
            args: %{},
            body: [
              %{
                kind: "variable_declaration",
                args: %{
                  label: "parent",
                  data_value: %{
                    kind: "coordinate",
                    args: %{
                      x: 0,
                      y: 0,
                      z: 0
                    }
                  }
                }
              }
            ]
          }
        },
        body: [move_block]
      }
      |> AST.decode()

    expect(Stubs, :get_current_x, 1, fn -> 100.00 end)
    expect(Stubs, :get_current_y, 1, fn -> 200.00 end)
    expect(Stubs, :get_current_z, 1, fn -> 300.00 end)

    expect(Stubs, :move_absolute, 1, fn 100.0, 200.0, 3, 23, 23, 4.0 ->
      :ok
    end)
    evaled = compile(ast)
    # IO.puts(evaled)
    Code.eval_string(evaled)
  end

  test "move to identifier" do
    ast =
      "test/fixtures/move_identifier.json"
      |> File.read!()
      |> Jason.decode!()
      |> AST.decode()

    expect(Stubs, :get_current_x, 1, fn -> 100.00 end)
    expect(Stubs, :get_current_y, 1, fn -> 200.00 end)
    expect(Stubs, :get_current_z, 1, fn -> 300.00 end)

    expect(Stubs, :move_absolute, 1, fn 100.0, 200.0, 3, 23, 23, 4.0 ->
      :ok
    end)

    Code.eval_string(compile(ast))
  end

  defp compile(ast) do
    IO.puts("TODO: Put this into helpers module.")

    ast
    |> Compiler.compile_ast([])
    |> Macro.to_string()
    |> Code.format_string!()
    |> IO.iodata_to_binary()
  end

  # defp strip_nl(text) do
  #   IO.puts("TODO: Put this into helpers module.")
  #   String.trim_trailing(text, "\n")
  # end
end
