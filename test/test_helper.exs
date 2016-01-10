ExUnit.start()

defmodule Echo do
  use GenServer
  require Logger

  def start(subject) do
    GenServer.start(__MODULE__, subject)
  end

  def handle_info({:echo, message}, subject) do
    send subject, message
    {:noreply, subject}
  end
end
