defmodule Apiproxy.Upstream do
  use GenServer

  defmodule State do
    defstruct protocol: "", host: "", port: "", socket: nil
  end

  def start_link(protocol, host, port) do
    GenServer.start_link(__MODULE__, [protocol, host, port])
  end

  def init([protocol, host, port]) do
    socket = Socket.TCP.connect! host, port, [:binary, packet: :line]
    {:ok, %State{host: host, port: port, socket: socket}}
  end

  def handle_call({:send, data}, _from, state) do
    :ok = Socket.Stream.send!(state.socket, data)
    {:reply, :ok, %{state | socket: state.socket}}
  end

  def handle_call(:recv, _from, state) do
    {:reply, Socket.Stream.recv!(state.socket, 0), state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def handle_info(_info, state) do
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    {:ok}
  end

  def code_change(_old_version, state, _extra) do
    {:ok, state}
  end

  def send_data(pid, data) do
    GenServer.call(pid, {:send, data})
  end

  def recv(pid) do
    GenServer.call(pid, :recv)
  end
end
