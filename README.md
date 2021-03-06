# Throttler [![Build Status](https://travis-ci.org/frojasg/throttler.svg?branch=master)](https://travis-ci.org/frojasg/throttler) [![Coverage Status](https://coveralls.io/repos/frojasg/throttler/badge.svg?branch=master&service=github)](https://coveralls.io/github/frojasg/throttler?branch=master)

## What's this about?
Let's say you application needs to make calls to an external service which has a restriction usage. You may only make X calls in Y seconds. With a throttler, you can ensure that calls you make do not cross the threshold rate.

# Example

```elixir
# A simple actor that prints whatever it receives
defmodule Printer do
  use GenServer

  def start(opts \\ []) do
    GenServer.start(__MODULE__, :ok, opts)
  end

  def handle_info({:print, x}, _state) do
    IO.puts "#{inspect x}"
    {:noreply, _state}
  end
end


{:ok, thr} = TimerBasedThrottler.start_link(messages: 3, period: 3*1000)
{:ok, printer} = Printer.start

#set target
TimerBasedThrottler.set_target(thr, printer)

#msg
TimerBasedThrottler.enqueue(thr, {:print, "Hello World"})
TimerBasedThrottler.enqueue(thr, {:print, "Hello World"})
TimerBasedThrottler.enqueue(thr, {:print, "Hello World"})

TimerBasedThrottler.enqueue(thr, {:print, "Hello World"})
TimerBasedThrottler.enqueue(thr, {:print, "Hello World"})

```
