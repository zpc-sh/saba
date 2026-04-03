defmodule SabaWeb.SabaLive.SessionShow do
  @moduledoc """
  Session detail — the core projection surface for watching discourse.
  Move timeline on the left, session metadata on the right.
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
  def mount(%{"id" => id}, _session, socket) do
    case Session.by_id(id) do
      {:ok, session} ->
        moves = Move.by_session!(session.id)

        {:ok,
         assign(socket,
           page_title: session.title || "Session",
           session: session,
           moves: moves,
           selected_move: nil
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
  def handle_event("select_move", %{"id" => move_id}, socket) do
    selected = Enum.find(socket.assigns.moves, &(&1.id == move_id))
    {:noreply, assign(socket, selected_move: selected)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto py-8 px-4">
      <%!-- Breadcrumb --%>
      <div class="text-sm breadcrumbs mb-4">
        <ul>
          <li><.link navigate={~p"/saba"}>Hall</.link></li>
          <li>{@session.title || "Session"}</li>
        </ul>
      </div>

      <%!-- Session header --%>
      <div class="flex items-start justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold">{@session.title || "Untitled"}</h1>
          <div class="flex items-center gap-2 mt-1">
            <.mode_badge mode={@session.mode} />
            <span class="text-sm text-base-content/50">{length(@moves)} moves</span>
            <div :if={@session.status == :live} class="w-2 h-2 rounded-full bg-success animate-pulse" />
          </div>
        </div>
        <div class="flex gap-2">
          <.link navigate={~p"/saba/sessions/#{@session.id}/tree"} class="btn btn-sm btn-outline">
            Tree View
          </.link>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <%!-- Move timeline (left 2/3) --%>
        <div class="lg:col-span-2 space-y-3">
          <div :for={move <- @moves} class="relative pl-6 pb-3">
            <%!-- Timeline connector --%>
            <div class="absolute left-2 top-0 bottom-0 w-px bg-base-300" />
            <div class={"absolute left-0.5 top-1 w-3 h-3 rounded-full border-2 #{move_dot_color(move.type)}"} />

            <div
              class={"card bg-base-200 shadow-sm cursor-pointer transition-all #{if @selected_move && @selected_move.id == move.id, do: "ring-2 ring-primary", else: "hover:bg-base-300"}"}
              phx-click="select_move"
              phx-value-id={move.id}
            >
              <div class="card-body p-3">
                <div class="flex items-center gap-2 mb-1">
                  <span class="font-mono text-sm font-semibold">{move.actor_id}</span>
                  <span class={"badge badge-xs #{move_color(move.type)}"}>{move.type}</span>
                  <span :if={move.target_ref} class="text-xs text-base-content/40 font-mono">
                    &rarr; {truncate_ref(move.target_ref)}
                  </span>
                </div>
                <%!-- Overlay text: the projection --%>
                <p class="text-sm">{get_in(move.payload, ["overlay"]) || "—"}</p>
                <%!-- Commitment receipt --%>
                <div class="mt-1 flex items-center gap-2">
                  <span class="text-[10px] font-mono text-base-content/30">{truncate_ref(move.id)}</span>
                  <.link
                    :if={move.actor_id}
                    navigate={~p"/saba/sessions/#{@session.id}/perspective/#{move.actor_id}"}
                    class="text-[10px] text-primary/50 hover:text-primary"
                  >
                    perspective &rarr;
                  </.link>
                </div>
              </div>
            </div>
          </div>

          <div :if={@moves == []} class="text-center py-12 text-base-content/40">
            No moves yet. The session is silent.
          </div>
        </div>

        <%!-- Sidebar (right 1/3) --%>
        <div class="space-y-4">
          <%!-- Participants --%>
          <div class="card bg-base-200">
            <div class="card-body p-4">
              <h3 class="font-semibold text-sm mb-2">Participants</h3>
              <div class="space-y-2">
                <.link
                  :for={p <- @session.participants}
                  navigate={~p"/saba/sessions/#{@session.id}/perspective/#{p}"}
                  class="flex items-center gap-2 hover:bg-base-300 rounded p-1 -mx-1"
                >
                  <span class="w-2 h-2 rounded-full bg-primary" />
                  <span class="font-mono text-sm">{p}</span>
                  <span class="text-xs text-base-content/40 ml-auto">
                    {count_moves_by(@moves, p)} moves
                  </span>
                </.link>
              </div>
            </div>
          </div>

          <%!-- Selected move detail --%>
          <div :if={@selected_move} class="card bg-base-200">
            <div class="card-body p-4">
              <h3 class="font-semibold text-sm mb-2">Move Detail</h3>
              <dl class="space-y-1 text-sm">
                <div class="flex justify-between">
                  <dt class="text-base-content/50">ID</dt>
                  <dd class="font-mono text-xs">{@selected_move.id}</dd>
                </div>
                <div class="flex justify-between">
                  <dt class="text-base-content/50">Type</dt>
                  <dd><span class={"badge badge-xs #{move_color(@selected_move.type)}"}>{@selected_move.type}</span></dd>
                </div>
                <div class="flex justify-between">
                  <dt class="text-base-content/50">Actor</dt>
                  <dd class="font-mono">{@selected_move.actor_id}</dd>
                </div>
                <div :if={@selected_move.target_ref} class="flex justify-between">
                  <dt class="text-base-content/50">Target</dt>
                  <dd class="font-mono text-xs">{@selected_move.target_ref}</dd>
                </div>
                <div :if={@selected_move.result_refs != []} class="flex flex-col gap-1">
                  <dt class="text-base-content/50">Result refs</dt>
                  <dd :for={ref <- @selected_move.result_refs} class="font-mono text-xs">{ref}</dd>
                </div>
              </dl>
            </div>
          </div>

          <%!-- Quick links --%>
          <div class="card bg-base-200">
            <div class="card-body p-4">
              <h3 class="font-semibold text-sm mb-2">Artifacts</h3>
              <p class="text-xs text-base-content/40">
                Nucleants and crystals crystallized from this discourse appear here.
              </p>
              <%!-- yata: artifact links will be populated when we can query nucleants by session --%>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp mode_badge(%{mode: :heat} = assigns) do
    ~H"""
    <span class="badge badge-sm badge-error font-bold">CAPITAL DAY</span>
    """
  end

  defp mode_badge(%{mode: :hangout} = assigns) do
    ~H"""
    <span class="badge badge-sm badge-ghost">hangout</span>
    """
  end

  defp mode_badge(assigns) do
    ~H"""
    <span class="badge badge-sm badge-ghost">{@mode}</span>
    """
  end

  defp move_color(type), do: Map.get(@move_colors, type, "badge-ghost")

  defp move_dot_color(:assert), do: "border-info bg-info/30"
  defp move_dot_color(:challenge), do: "border-error bg-error/30"
  defp move_dot_color(:clarify), do: "border-warning bg-warning/30"
  defp move_dot_color(:concede), do: "border-success bg-success/30"
  defp move_dot_color(:fork), do: "border-secondary bg-secondary/30"
  defp move_dot_color(:crystallize), do: "border-accent bg-accent/30"
  defp move_dot_color(_), do: "border-base-content/30 bg-base-300"

  defp truncate_ref(ref) when byte_size(ref) > 16, do: String.slice(ref, 0, 16) <> "..."
  defp truncate_ref(ref), do: ref

  defp count_moves_by(moves, actor_id) do
    Enum.count(moves, &(&1.actor_id == actor_id))
  end
end
