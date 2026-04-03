defmodule SabaWeb.SabaLive.Hall do
  @moduledoc """
  The hall lobby — projection surface for listing discourse sessions.
  """
  use SabaWeb, :live_view

  on_mount {SabaWeb.LiveUserAuth, :live_user_optional}

  alias Saba.Sabha.Session

  @impl true
  def mount(_params, _session, socket) do
    live_sessions = Session.list_live!()
    ended_sessions = Session.list_ended!()
    archived_sessions = Session.list_archived!()

    {:ok,
     assign(socket,
       page_title: "Saba — The Hall",
       live_sessions: live_sessions,
       ended_sessions: ended_sessions,
       archived_sessions: archived_sessions,
       active_tab: "live"
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-8 px-4">
      <div class="mb-8">
        <h1 class="text-3xl font-bold tracking-tight">Saba</h1>
        <p class="text-base-content/60 mt-1">The discourse hall. What you see here is a projection.</p>
      </div>

      <%!-- Tab navigation --%>
      <div class="tabs tabs-bordered mb-6">
        <button
          class={"tab #{if @active_tab == "live", do: "tab-active"}"}
          phx-click="switch_tab"
          phx-value-tab="live"
        >
          Live
          <span :if={@live_sessions != []} class="ml-2 badge badge-sm badge-success animate-pulse">
            {length(@live_sessions)}
          </span>
        </button>
        <button
          class={"tab #{if @active_tab == "ended", do: "tab-active"}"}
          phx-click="switch_tab"
          phx-value-tab="ended"
        >
          Ended
          <span :if={@ended_sessions != []} class="ml-2 badge badge-sm badge-ghost">
            {length(@ended_sessions)}
          </span>
        </button>
        <button
          class={"tab #{if @active_tab == "archived", do: "tab-active"}"}
          phx-click="switch_tab"
          phx-value-tab="archived"
        >
          Archived
          <span :if={@archived_sessions != []} class="ml-2 badge badge-sm badge-ghost">
            {length(@archived_sessions)}
          </span>
        </button>
      </div>

      <%!-- Session list --%>
      <div class="space-y-4">
        <.session_list
          :if={@active_tab == "live"}
          sessions={@live_sessions}
          empty_message="No live sessions. The hall is quiet."
        />
        <.session_list
          :if={@active_tab == "ended"}
          sessions={@ended_sessions}
          empty_message="No ended sessions yet."
        />
        <.session_list
          :if={@active_tab == "archived"}
          sessions={@archived_sessions}
          empty_message="Nothing archived."
        />
      </div>
    </div>
    """
  end

  defp session_list(assigns) do
    ~H"""
    <div :if={@sessions == []} class="text-center py-12 text-base-content/40">
      {@empty_message}
    </div>
    <div :for={session <- @sessions} class="card bg-base-200 shadow-sm">
      <div class="card-body p-4">
        <div class="flex items-start justify-between">
          <div>
            <.link
              navigate={~p"/saba/sessions/#{session.id}"}
              class="text-lg font-semibold hover:underline"
            >
              {session.title || "Untitled Session"}
            </.link>
            <div class="flex items-center gap-2 mt-1">
              <.mode_badge mode={session.mode} />
              <span class="text-xs text-base-content/50">
                {length(session.participants)} participants
              </span>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <div :if={session.status == :live} class="w-2 h-2 rounded-full bg-success animate-pulse" />
            <span class="text-xs text-base-content/40">
              {format_time(session.provenance["created_at"])}
            </span>
          </div>
        </div>
        <%!-- Participant avatars --%>
        <div class="flex gap-1 mt-2">
          <span
            :for={p <- session.participants}
            class="badge badge-outline badge-sm font-mono"
          >
            {p}
          </span>
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

  defp mode_badge(%{mode: :seminar} = assigns) do
    ~H"""
    <span class="badge badge-sm badge-info">seminar</span>
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

  defp format_time(nil), do: ""

  defp format_time(time_str) when is_binary(time_str) do
    case DateTime.from_iso8601(time_str) do
      {:ok, dt, _} -> Calendar.strftime(dt, "%b %d, %H:%M UTC")
      _ -> time_str
    end
  end

  defp format_time(_), do: ""
end
