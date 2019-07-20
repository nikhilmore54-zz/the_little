defmodule Metex.Worker do
  use GenServer
  require Logger

  ## Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_temperature(pid, location) do
    GenServer.call(pid, {:location, location})
  end

  ## Server Callbacks
  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:location, location}, _from, state) do
    case temperature_of(location) do
      temp ->
        new_state = update_state(state, location)
        {:reply, "#{temp}°C", new_state}
      location ->
        {:reply, :error, state}
    end
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
    :error_in_parse_response
  end

  defp compute_temperature(json) do
    try do
      temp = (json["main"]["temp"] - 273.15) |> Float.round(1)
    rescue
      _ -> 
        :error_in_compute_temperature
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
