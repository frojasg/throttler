# Throttler

## What's this about?
Let's say you application needs to make calls to an external service which has a restriction usage. You may only make X calls in Y seconds. With a throtler, you can ensure that calls you make do not cross the threshold rate.

# Example

```elixir
# A simple actor that prints whatever it receives
defmodule Printer do
  use Genserver

  def print(server, x) do
    GenServer.cast(server, {print, x})
  end

  def start(opts \\ []) do
    GenServer.start(__MODULE__, :ok, opts)
  end

  def handle_cast({:print, x}, _state) do
    IO.puts "#{inspect x}"
    {:noreply, _sate}
  end
end


printer = Printer.start
throttler = TimerBasedThrottler.start(messages: 3, per: 3000, target: printer)

Printer.print(throttler, 1)
Printer.print(throttler, 2)
Printer.print(throttler, 3)


Printer.print(throttler, 4)
Printer.print(throttler, 5)
```
