defmodule TimerBasedThrottlerTest do
  use ExUnit.Case

  test "keep messages until target is set" do
    {:ok, thr} = TimerBasedThrottler.start_link(messages: 3, period: 3*1000)
    {:ok, echo} = Echo.start(self)
    TimerBasedThrottler.enqueue(thr, {:echo, :one})
    TimerBasedThrottler.enqueue(thr, {:echo, :two})
    TimerBasedThrottler.enqueue(thr, {:echo, :three})
    refute_receive _
    TimerBasedThrottler.set_target(thr, echo)
    assert_receive :one
    assert_receive :two
    assert_receive :three
  end

  test "respect rate 3 messages per second" do
    {:ok, thr} = TimerBasedThrottler.start_link(messages: 3, period: 3*1000)
    {:ok, echo} = Echo.start(self)
    TimerBasedThrottler.set_target(thr, echo)
    TimerBasedThrottler.enqueue(thr, {:echo, :one})
    TimerBasedThrottler.enqueue(thr, {:echo, :two})
    TimerBasedThrottler.enqueue(thr, {:echo, :three})
    TimerBasedThrottler.enqueue(thr, {:echo, :four})
    TimerBasedThrottler.enqueue(thr, {:echo, :five})
    assert_receive :one
    assert_receive :two
    assert_receive :three

    refute_receive _, 3*1000
    assert_receive :four
    assert_receive :five
  end

  test "comeback to idle state when target dies" do
    {:ok, thr} = TimerBasedThrottler.start_link(messages: 3, period: 3*1000)
    {:ok, echo} = Echo.start(self)
    TimerBasedThrottler.set_target(thr, echo)
    TimerBasedThrottler.enqueue(thr, {:echo, :one})
    TimerBasedThrottler.enqueue(thr, {:echo, :two})
    assert_receive :one
    assert_receive :two

    Process.exit(echo, :kill)

    refute_receive _, 3*1000
    TimerBasedThrottler.enqueue(thr, {:echo, :one})

    {:ok, echo} = Echo.start(self)
    TimerBasedThrottler.set_target(thr, echo)
    TimerBasedThrottler.enqueue(thr, {:echo, :two})
    assert_receive :one
    assert_receive :two
  end

end
