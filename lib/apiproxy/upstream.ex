defmodule Apiproxy.Upstream do
  use GenServer

  defmodule State do
    defstruct protocol: "", host: "", port: "", socket: nil
  end

  def start_link(protocol, host, port) do
    GenServer.start_link(__MODULE__, [protocol, host, port])
  end

  def init([protocol, host, port]) do
    {:ok, socket} = :gen_tcp.connect(String.to_char_list(host), port, [:binary, packet: 0, active: false, reuseaddr: true, nodelay: true])
    {:ok, %State{host: host, port: port, socket: socket, protocol: protocol}}
  end

  def handle_call({:send, data}, _from, state) do
    :ok = :gen_tcp.send(state.socket, data)
    {:reply, :ok, %{state | socket: state.socket}}
  end

  def handle_call(:recv, _from, state) do
    case :gen_tcp.recv(state.socket, 0, 10) do
      {:ok, data} -> {:reply, {:data, data}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
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
