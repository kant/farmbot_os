defmodule FarmbotExt.AMQP.BotStateChannel do
  @moduledoc """
  Publishes JSON encoded bot state updates onto an AMQP channel
  """

  use GenServer
  use AMQP

  require FarmbotCore.Logger
  require FarmbotTelemetry
  alias FarmbotCore.{BotState, BotStateNG}
  alias FarmbotCore.JSON
  alias FarmbotExt.AMQP.Support

  @exchange "amq.topic"

  defstruct [:conn, :chan, :jwt, :cache]
  alias __MODULE__, as: State

  @doc "Forces pushing the most current state tree"
  def read_status do
    GenServer.cast(__MODULE__, :force)
  end

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(args) do
    jwt = Keyword.fetch!(args, :jwt)
    cache = BotState.subscribe()
    {:ok, %State{conn: nil, chan: nil, jwt: jwt, cache: cache}, 0}
  end

  @impl GenServer
  def terminate(r, s), do: Support.handle_termination(r, s, "BotState")

  @impl GenServer
  def handle_cast(:force, state) do
    cache = BotState.fetch()
    {:noreply, %{state | cache: cache}, {:continue, :dispatch}}
  end

  @impl GenServer
  def handle_info(:timeout, %{conn: nil, chan: nil} = state) do
    with {:ok, {conn, chan}} <- FarmbotExt.AMQP.Support.create_channel() do
      FarmbotTelemetry.event(:amqp, :channel_open)
      {:noreply, %{state | conn: conn, chan: chan}, {:continue, :dispatch}}
    else
      nil ->
        {:noreply, %{state | conn: nil, chan: nil}, 5000}

      err ->
        FarmbotTelemetry.event(:amqp, :channel_open_error, nil, error: inspect(err))
        FarmbotCore.Logger.error(1, "Failed to connect to BotState channel: #{inspect(err)}")
        {:noreply, %{state | conn: nil, chan: nil}, 1000}
    end
  end

  def handle_info(:timeout, %{chan: %{}} = state) do
    {:noreply, state, {:continue, :dispatch}}
  end

  def handle_info({BotState, change}, state) do
    cache = Ecto.Changeset.apply_changes(change)
    {:noreply, %{state | cache: cache}, {:continue, :dispatch}}
  end

  @impl GenServer
  def handle_continue(:dispatch, %{chan: nil} = state) do
    {:noreply, state, 5000}
  end

  def handle_continue(:dispatch, %{chan: %{}, cache: cache} = state) do
    json =
      cache
      |> BotStateNG.view()
      |> JSON.encode!()

    Basic.publish(state.chan, @exchange, "bot.#{state.jwt.bot}.status", json)
    {:noreply, state, 5000}
  end
end
