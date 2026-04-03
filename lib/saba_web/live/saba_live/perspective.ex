defmodule SabaWeb.SabaLive.Perspective do
  @moduledoc """
  Agent perspective view — follow one intelligence's reasoning journey
  through the discourse. The audience picks a mind and sees its path.
  """
  use SabaWeb, :live_view

  on_mount {SabaWeb.LiveUserAuth, :live_user_optional}

  alias Saba.Sabha.{Session, Move}

  @move_colors %{
    assert: "badge-info",
    challenge: "badge-error",
    clarify: "badge-warning",
    concede: "badge-success",
    fork: "badge-secondary",
    fold: "badge-ghost",
    collapse: "badge-ghost",
    crystallize: "badge-accent",
    reframe: "badge-secondary",
    invoke: "badge-primary"
  }

  @impl true
  def mount(%{"id" => session_id, "agent_id" => agent_id}, _session, socket) do
    case Session.by_id(session_id) do
      {:ok, session} ->
        all_moves = Move.by_session!(session.id)
        agent_moves = Move.by_actor!(session.id, agent_id)
        agent_move_ids = MapSet.new(agent_moves, & &1.id)

        # Move type distribution
        type_dist =
          agent_moves
          |> Enum.frequencies_by(& &1.type)
          |> Enum.sort_by(fn {_type, count} -> -count end)

        # Nodes this agent touched
        touched_nodes =
          agent_moves
          |> Enum.flat_map(fn m -> [m.target_ref | m.result_refs] end)
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()

        {:ok,
         assign(socket,
           page_title: "#{agent_id} — #{session.title || "Session"}",
           session: session,
           agent_id: agent_id,
           all_moves: all_moves,
           agent_moves: agent_moves,
           agent_move_ids: agent_move_ids,
           type_dist: type_dist,
           touched_nodes: touched_nodes
         )}

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Session not found")
         |> push_navigate(to: ~p"/saba")}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-8 px-4">
      <%!-- Breadcrumb --%>
      <div class="text-sm breadcrumbs mb-4">
        <ul>
          <li><.link navigate={~p"/saba"}>Hall</.link></li>
          <li><.link navigate={~p"/saba/sessions/#{@session.id}"}>{@session.title || "Session"}</.link></li>
          <li>{@agent_id}</li>
        </ul>
      </div>

      <%!-- Agent header --%>
      <div class="mb-6">
        <h1 class="text-2xl font-bold font-mono">{@agent_id}</h1>
        <p class="text-base-content/50 text-sm mt-1">
          {length(@agent_moves)} moves across {length(@touched_nodes)} nodes
        </p>
      </div>

      <%!-- Perspective switcher --%>
      <div class="flex gap-2 mb-6">
        <.link
          :for={p <- @session.participants}
          navigate={~p"/saba/sessions/#{@session.id}/perspective/#{p}"}
          class={"btn btn-sm #{if p == @agent_id, do: "btn-primary", else: "btn-ghost"}"}
        >
          {p}
        </.link>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <%!-- Move timeline in context (left 2/3) --%>
        <div class="lg:col-span-2 space-y-2">
          <h2 class="font-semibold text-sm text-base-content/50 mb-3">Reasoning Journey</h2>
          <div :for={move <- @all_moves} class="relative pl-6">
            <%!-- Timeline connector --%>
            <div class="absolute left-2 top-0 bottom-0 w-px bg-base-300" />
            <div class={"absolute left-0.5 top-1 w-3 h-3 rounded-full #{if MapSet.member?(@agent_move_ids, move.id), do: "bg-primary border-2 border-primary", else: "bg-base-300 border-2 border-base-300"}"} />

            <div class={"card shadow-sm mb-2 #{if MapSet.member?(@agent_move_ids, move.id), do: "bg-base-200 ring-1 ring-primary/30", else: "bg-base-100/50 opacity-40"}"}>
              <div class="card-body p-3">
                <div class="flex items-center gap-2 mb-1">
                  <span class={"font-mono text-sm #{if move.actor_id == @agent_id, do: "font-bold"}"}>{move.actor_id}</span>
                  <span class={"badge badge-xs #{move_color(move.type)}"}>{move.type}</span>
                </div>
                <p class="text-sm">{get_in(move.payload, ["overlay"]) || "—"}</p>
              </div>
            </div>
          </div>
        </div>

        <%!-- Stats sidebar (right 1/3) --%>
        <div class="space-y-4">
          <%!-- Move type distribution --%>
          <div class="card bg-base-200">
            <div class="card-body p-4">
              <h3 class="font-semibold text-sm mb-3">Move Distribution</h3>
              <div class="space-y-2">
                <div :for={{type, count} <- @type_dist} class="flex items-center justify-between">
                  <span class={"badge badge-xs #{move_color(type)}"}>{type}</span>
                  <div class="flex items-center gap-2">
                    <div class="w-24 bg-base-300 rounded-full h-2">
                      <div
                        class="bg-primary rounded-full h-2"
                        style={"width: #{count / length(@agent_moves) * 100}%"}
                      />
                    </div>
                    <span class="text-xs font-mono w-4 text-right">{count}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <%!-- Nodes touched --%>
          <div class="card bg-base-200">
            <div class="card-body p-4">
              <h3 class="font-semibold text-sm mb-2">Nodes Touched</h3>
              <div class="flex flex-wrap gap-1">
                <span :for={ref <- @touched_nodes} class="badge badge-outline badge-xs font-mono">
                  {truncate_ref(ref)}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp move_color(type), do: Map.get(@move_colors, type, "badge-ghost")

  defp truncate_ref(ref) when byte_size(ref) > 16, do: String.slice(ref, 0, 16) <> "..."
  defp truncate_ref(ref), do: ref
end
