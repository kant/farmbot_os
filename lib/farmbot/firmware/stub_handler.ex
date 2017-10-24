defmodule Farmbot.Firmware.StubHandler do
  @moduledoc "Stubs out firmware functionality when you don't have an arduino."

  use GenStage
  require Logger

  @behaviour Farmbot.Firmware.Handler
  alias Farmbot.Firmware.Vec3

  ## Firmware Handler Behaviour.

  def start_link do
    Logger.warn("Firmware is being stubbed.")
    GenStage.start_link(__MODULE__, [])
  end

  def move_absolute(handler, pos) do
    GenStage.call(handler, {:move_absolute, pos})
  end

  def calibrate(handler, axis) do
    GenStage.call(handler, {:calibrate, axis})
  end

  def find_home(handler, axis) do
    GenStage.call(handler, {:find_home, axis})
  end

  def zero(handler, axis) do
    GenStage.call(handler, {:zero, axis})
  end

  def update_param(handler, param, val) do
    GenStage.call(handler, {:update_param, param, val})
  end

  def read_param(handler, param) do
    GenStage.call(handler, {:read_param, param})
  end

  def emergency_lock(handler) do
    GenStage.call(handler, :emergency_lock)
  end

  def emergency_unlock(handler) do
    GenStage.call(handler, :emergency_unlock)
  end

  def read_pin(handler, pin, pin_mode) do
    GenStage.call(handler, {:read_pin, pin, pin_mode})
  end

  def write_pin(handler, pin, pin_mode, value) do
    GenStage.call(handler, {:write_pin, pin, pin_mode, value})
  end

  ## GenStage Behaviour

  defmodule State do
    defstruct pos: nil,
              fw_params: %{},
              locked?: false
  end

  def init([]) do
    state = %State{pos: struct(Vec3)}
    {:producer, state, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_demand(_amnt, state) do
    {:noreply, [], state}
  end

  def handle_call({:move_absolute, pos}, _from, state) do
    {:reply, :ok, [{:report_current_position, pos.x, pos.y, pos.z}], %{state | pos: pos}}
  end

  def handle_call({:calibrate, _axis}, _from, state) do
    {:reply, :ok, [], state}
  end

  def handle_call({:find_home, _axis}, _from, state) do
    {:reply, :ok, [], state}
  end

  def handle_call({:zero, axis}, _from, state) do
    state = %{state | pos: %{state.pos | axis => 0}}
    case axis do
      :x -> {:reply, :ok, [{:report_current_position, 0, state.pos.y, state.pos.z}], state}
      :y -> {:reply, :ok, [{:report_current_position, state.pos.x, 0, state.pos.z}], state}
      :z -> {:reply, :ok, [{:report_current_position, state.pos.x, state.pos.y, 0}], state}
    end
  end

  def handle_call({:update_param, param, val}, _from, state) do
    {:reply, :ok, [], %{state | fw_params: Map.put(state.fw_params, param, val)}}
  end

  def handle_call({:read_param, param}, _from, state) do
    {:reply, state.fw_params[param], [], state}
  end

  def handle_call(:emergency_lock, _from, state) do
    {:reply, :ok, [], state}
  end

  def handle_call(:emergency_unlock, _from, state) do
    {:reply, :ok, [], state}
  end
end
