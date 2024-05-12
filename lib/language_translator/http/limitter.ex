defmodule LanguageTranslator.Http.Limitter do
  use GenServer

  alias LanguageTranslator.Http.Wrapper

  defmodule PendingRequest do
    defstruct method: nil, url: nil, headers: nil, body: nil, ref: nil, caller: nil

    def new(method, url, headers, body, ref, caller) do
      %__MODULE__{
        method: method,
        url: url,
        headers: headers,
        body: body,
        ref: ref,
        caller: caller
      }
    end
  end

  defstruct delay: 0, pending_requests: []

  def make_request(method, url, headers, body \\ %{}) do
    ref = make_ref()
    GenServer.cast(__MODULE__, {:request, method, url, headers, body, ref, self()})

    receive do
      {:response, ^ref, response} -> response
    end
  end

  def start_link(%{requests_per_second: _} = opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(%{requests_per_second: requests_per_second}) do
    delay = div(1000, requests_per_second)
    Process.send_after(self(), :tick, delay)

    {:ok, %__MODULE__{delay: delay, pending_requests: []}}
  end

  @impl true
  def handle_cast(
        {:request, method, url, headers, body, ref, caller},
        %__MODULE__{
          pending_requests: pending_requests
        } = state
      ) do
    new_pending_requests =
      pending_requests ++ [PendingRequest.new(method, url, headers, body, ref, caller)]

    {:noreply, %{state | pending_requests: new_pending_requests}}
  end

  @impl true
  def handle_info(:tick, %__MODULE__{pending_requests: [], delay: delay} = state) do
    Process.send_after(self(), :tick, delay)
    {:noreply, state}
  end

  @impl true
  def handle_info(
        :tick,
        %__MODULE__{pending_requests: [pending_request | rest], delay: delay} = state
      ) do
    send_request(pending_request)
    Process.send_after(self(), :tick, delay)
    {:noreply, %{state | pending_requests: rest}}
  end

  @impl true
  def handle_info({_ref, :ok}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:noreply, state}
  end

  defp send_request(%PendingRequest{
         method: method,
         url: url,
         headers: headers,
         body: body,
         ref: ref,
         caller: caller
       }) do
    Task.Supervisor.async_nolink(LanguageTranslator.TaskSupervisor, fn ->
      response =
        case method do
          :get -> Wrapper.get(url, headers)
          :post -> Wrapper.post(url, body, headers)
        end

      Process.send(caller, {:response, ref, response}, [])
    end)
  end
end
