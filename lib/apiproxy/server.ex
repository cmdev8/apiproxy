defmodule Apiproxy.Server do

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: 0, active: false, reuseaddr: true, nodelay: true])
    IO.puts "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    spawn(fn -> serve(client) end)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    {:ok, upstream} = Apiproxy.Upstream.start_link(:tcp, "localhost", 1337)
    spawn(fn -> receive_data(socket, upstream) end)
    spawn(fn -> response(socket, upstream) end)
  end

  defp receive_data(socket, upstream) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        # IO.puts data
        Apiproxy.Upstream.send_data(upstream, data)
        receive_data(socket, upstream)
      {:error, reason} ->
        # IO.puts reason
    end
  end

  defp response(socket, upstream) do
    case Apiproxy.Upstream.recv(upstream) do
      {:data, data} ->
        :gen_tcp.send(socket, data)
        response(socket, upstream)
      {:error, :timeout} ->
        response(socket, upstream)
      {:error, :ebadf} ->
        :gen_tcp.close(socket)
      {:error, :closed} ->
    end
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end
end
