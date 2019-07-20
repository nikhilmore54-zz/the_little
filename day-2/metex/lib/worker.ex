defmodule Metex.Worker do
  use GenServer
  @name MW

  ## Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: MW])
  end

  def get_temperature(location) do
    GenServer.call(@name, {:location, location})
  end

  def get_stats() do
    GenServer.call(@name, :get_state)
  end

  def reset_stats() do
    GenServer.cast(@name, :reset_state)
  end

  def stop() do
    GenServer.cast(@name, :stop)
  end

  ## Server Callbacks
  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:location, location}, _from, state) do
    case temperature_of(location) do
      :error ->
        {:reply, :error, state}
      temp ->
        new_state = update_state(state, location)
        {:reply, "#{temp}°C", new_state}
    end
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast(:reset_state, _state) do
    {:noreply, %{}}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    IO.puts "received #{inspect msg}"
    {:noreply, state}
  end

  def terminate(reason, state) do
    IO.puts "server terminated because of #{inspect reason}"
      inspect state
    :ok
  end

  ## Helper Functions

  defp temperature_of(location) do
    location |> url_for |> HTTPoison.get |> parse_response
  end

  defp url_for(location) do 
    "https://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{apikey}" 
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> JSON.decode! |> compute_temperature
  end

  defp parse_response(params) do
    :error
  end

  defp compute_temperature(json) do
    try do
      temp = (json["main"]["temp"] - 273.15) |> Float.round(1)
    rescue
      _ -> 
        :error
    end
  end

  def apikey() do
    "9c5cabda9e2c6013de447aa4dbb236b5"
  end

  defp update_state(old_state, location) do
    case Map.has_key?(old_state, location) do
      true ->
        Map.update!(old_state, location, &(&1 + 1))
      false ->
        Map.put_new(old_state, location, 1)
    end
  end
end
