defmodule Xest.APIServer do
  @moduledoc """
  A module to encapsulate GenServer, when we want to minimize requests to it, based on time.

  This is useful when a large number of client rely on a function which side effect doesn't depend much on time.

  It basically trades request/response messages, for a large number of subscriber,
  by temporarily memoizing and broadcasting responses.

  It is also useful in a context when realworld effects (like an API call) must be minimized.
  It is shortlived, to forget previous results and force new requests.

  #Ref for monadification :
  # - https://www.cs.utexas.edu/~wcook/Drafts/2009/sblp09-memo-mixins.pdf
  # - https://kseo.github.io/posts/2017-01-21-writer-monad.html
  """

  # TODO : usage pattern : https://stackoverflow.com/questions/37622783/how-can-i-provide-a-default-implementation-of-a-function-without-causing-warning

  require GenServer

  @type lifetime :: Time.t()

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      # using APIServer, is the same as using GenServer.
      use GenServer

      @behaviour Xest.APIServer

      def child_spec(init_arg) do
        default = %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [init_arg]}
        }

        Supervisor.child_spec(default, unquote(Macro.escape(opts)))
      end

      @impl true
      def handle_call(request, from, state) do
        {tmap, actual_state} = state
        # Note: actual state should !never! impact request/response
        case Xest.TransientMap.fetch(tmap, request) do
          {:ok, hit} ->
            {:reply, hit, state}

          :error ->
            case mockable_impl().handle_cachemiss(request, from, actual_state) do
              {:reply, reply, new_state} ->
                tmap = Xest.TransientMap.put(tmap, request, reply)
                {:reply, reply, {tmap, new_state}}

              {:noreply, new_state} ->
                {:noreply, {tmap, new_state}}

                # TODO: more possible replies
            end
        end
      end

      #    @impl true
      #    def mockable_impl() do
      #        return Application.get_env(:xest, :api_server_mockable_impl, __MODULE__)
      #    end
    end
  end

  @spec start_link(GenServer.module(), any, GenServer.options()) :: GenServer.on_start()
  def start_link(module, init_arg, options \\ []) when is_atom(module) and is_list(options) do
    # Here we add a trasient map to use as cache
    # and prevent call to be handled in client code when possible
    lifetime = Keyword.get(options, :lifetime, nil)
    tmap = Xest.TransientMap.new(lifetime)
    # leveraging GenServer behaviour
    GenServer.start_link(module, {tmap, init_arg}, options)
  end

  @spec call(GenServer.server(), term, timeout) :: term
  def call(server, request, timeout \\ 5000) do
    GenServer.call(server, request, timeout)
  end

  # SAME spec as handle_call
  # reply, new_state}
  @callback handle_cachemiss(request :: term, GenServer.from(), state :: term) ::
              {:reply, term, term}
  #              | {:reply, reply, new_state, timeout | :hibernate | {:continue, term}}
  #              | {:noreply, new_state}
  #              | {:noreply, new_state, timeout | :hibernate | {:continue, term}}
  #              | {:stop, reason, reply, new_state}
  #              | {:stop, reason, new_state}
  #            when reply: term, new_state: term, reason: term

  @callback mockable_impl() :: term
end
