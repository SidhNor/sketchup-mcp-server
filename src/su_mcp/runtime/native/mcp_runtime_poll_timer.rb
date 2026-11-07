# frozen_string_literal: true

module SU_MCP
  # Owns the repeating host timer that drives the HTTP backend's polling.
  #
  # Polls quickly while the transport is active so request bursts and large
  # responses are not paced by the idle interval, and falls back to the idle
  # interval once traffic stops.
  class McpRuntimePollTimer
    IDLE_INTERVAL = 0.1
    ACTIVE_INTERVAL = 0.01

    def initialize(timer_starter:, timer_stopper:, on_stop_error:)
      @timer_starter = timer_starter
      @timer_stopper = timer_stopper
      @on_stop_error = on_stop_error
      @timer_id = nil
      @interval = nil
    end

    def start(&tick)
      @tick = tick
      schedule(IDLE_INTERVAL)
    end

    def stop
      timer_stopper.call(@timer_id) if @timer_id
    rescue StandardError => e
      on_stop_error.call(e)
    ensure
      @timer_id = nil
      @interval = nil
    end

    def running?
      !@timer_id.nil?
    end

    # Switches to the interval matching the activity, restarting only on change.
    def pace(active:)
      interval = active ? ACTIVE_INTERVAL : IDLE_INTERVAL
      return if !running? || interval == @interval

      stop
      schedule(interval)
    end

    private

    attr_reader :timer_starter, :timer_stopper, :on_stop_error

    def schedule(interval)
      @interval = interval
      @timer_id = timer_starter.call(interval, true) { @tick.call }
    end
  end
end
