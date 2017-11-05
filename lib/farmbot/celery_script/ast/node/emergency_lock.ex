defmodule Farmbot.CeleryScript.AST.Node.EmergencyLock do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []

  def execute(_, _, env) do
    case Farmbot.Firmware.emergency_lock do
      :ok -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end
