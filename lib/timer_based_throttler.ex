defmodule TimerBasedThrottler do
  @behaviour :gen_fsm
  require Logger

  @period 1*1000
  @messages 10

  defstruct [
    target: nil,
    messages_left_in_period: 0,
    messages_per_period: 0,
    period: 1000, #1 second
    queue: [],
    timer: nil
  ]

  #public
  def start_link(args) do
    :gen_fsm.start_link(__MODULE__, args, [])
  end

  def set_target(throttler, target) do
    :gen_fsm.send_event(throttler, {:set_target, target})
  end

  def enqueue(throttler, msg) do
    :gen_fsm.send_event(throttler, {:queue, msg})
  end

  #state machine
  def idle({:set_target, target}, state = %TimerBasedThrottler{queue: []}) do
    Process.monitor(target)
    {:next_state, :idle, %{state | target: target}}
  end

  def idle({:set_target, target}, state) do
    Process.monitor(target)
    state = %{state | target: target} |> deliver_messages |> timer
    {:next_state, :active, state}
  end

  def idle({:queue, msg}, state = %TimerBasedThrottler{target: nil, queue: q}) do
    {:next_state, :idle, %{state | queue: ([msg | q] |> Enum.reverse)}}
  end

  def idle({:queue, msg}, state = %TimerBasedThrottler{target: target, queue: []}) when is_nil(target) == false do
    state = %{state | queue: [msg]} |> deliver_messages |> timer
    {:next_state, :active, state}
  end

  def idle(:tick, state) do
    {:next_state, :active, %{state | timer: nil}}
  end

  def idle(_msg, state) do
    {:next_state, :idle, state}
  end

  def active({:queue, msg}, state = %TimerBasedThrottler{queue: q}) do
    state = %{state | queue: ([msg | q] |> Enum.reverse)} |> deliver_messages
    {:next_state, :active, state}
  end

  def active(:tick, state = %TimerBasedThrottler{queue: []}) do
    {:next_state, :idle, %{state | timer: nil, messages_left_in_period: state.messages_per_period}}
  end

  def active(:tick, state) do
    state = %{state | messages_left_in_period: state.messages_per_period} |> deliver_messages |> timer
    {:next_state, :active, state}
  end

  def deliver_messages(state) do
    message_to_send = min(length(state.queue), state.messages_left_in_period)
    state.queue |> Enum.take(message_to_send) |> Enum.each fn(message) -> send state.target, message end
    %{state | queue: Enum.drop(state.queue, message_to_send), messages_left_in_period: (state.messages_left_in_period - message_to_send)}
  end

  def timer(state) do
    %{state | timer: Process.send_after(self(), :tick, state.period)}
  end

  # OTP
  def init(args) do
    state = %TimerBasedThrottler{
      messages_left_in_period: Keyword.get(args, :messages, @messages),
      messages_per_period:  Keyword.get(args, :messages, @messages),
      period:  Keyword.get(args, :period, @period),
      timer: nil
    }
    {:ok, :idle, state}
  end

  def handle_info(:tick, state_name, state) do
    # Logger.info "time! state_name: #{inspect state_name} state: #{inspect state}"
    :gen_fsm.send_event(self, :tick)
    {:next_state, state_name, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state_name, state = %TimerBasedThrottler{target: target}) do
    if(pid == target) do
      {:next_state, :idle, %{state | target: nil, queue: [], messages_left_in_period: state.messages_per_period}}
    else
      {:next_state, state_name, state}
    end
  end

  def terminate(reason, state_name, state) do
    Logger.info "#{inspect state_name} reason: #{inspect reason} status: #{inspect state}"
  end

  def format_status(_reason, [ _pdict, state ]) do
    [data: [{'State', "My current state is '#{inspect state}', and I'm happy"}]]
  end
end
