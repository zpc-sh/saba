defmodule SabaWeb.SabaLive.CrystalShow do
  @moduledoc """
  Crystal inspector — composed artifact from multiple nucleants.
  Shows structure, constituent nucleants, proofs, and replay layers.
  """
  use SabaWeb, :live_view

  on_mount {SabaWeb.LiveUserAuth, :live_user_optional}

  alias Saba.Sabha.Crystal

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    crystals = Crystal.by_tree!(id)

    case crystals do
      [crystal | _] ->
        replay_layers =
          (crystal.replay || %{})
          |> Enum.sort_by(fn {key, _} -> key end)

        {:ok,
         assign(socket,
           page_title: "Crystal — #{id}",
           crystal: crystal,
           replay_layers: replay_layers,
           expanded_layers: MapSet.new(["L0"])
         )}

      [] ->
        # yata: need a by_id action on Crystal
        {:ok,
         socket
         |> put_flash(:error, "Crystal not found")
         |> push_navigate(to: ~p"/saba")}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_layer", %{"layer" => layer}, socket) do
    expanded = socket.assigns.expanded_layers

    expanded =
      if MapSet.member?(expanded, layer),
        do: MapSet.delete(expanded, layer),
        else: MapSet.put(expanded, layer)

    {:noreply, assign(socket, expanded_layers: expanded)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-8 px-4">
      <%!-- Breadcrumb --%>
      <div class="text-sm breadcrumbs mb-4">
        <ul>
          <li><.link navigate={~p"/saba"}>Hall</.link></li>
          <li>Crystal</li>
        </ul>
      </div>

      <div class="mb-6">
        <h1 class="text-2xl font-bold">Crystal</h1>
        <p class="text-xs font-mono text-base-content/40 mt-1">{@crystal.id}</p>
      </div>

      <%!-- Claims --%>
      <div class="card bg-base-200 mb-6">
        <div class="card-body p-4">
          <h2 class="font-semibold text-sm mb-2">Claims</h2>
          <div class="flex flex-wrap gap-2">
            <span :for={claim <- @crystal.claims || []} class="badge badge-outline badge-sm">
              {claim}
            </span>
          </div>
        </div>
      </div>

      <%!-- Constituent nucleants --%>
      <div class="card bg-base-200 mb-6">
        <div class="card-body p-4">
          <h2 class="font-semibold text-sm mb-2">Constituent Nucleants</h2>
          <div class="space-y-1">
            <.link
              :for={nuc_id <- @crystal.nucleant_ids || []}
              navigate={~p"/saba/nucleants/#{nuc_id}"}
              class="block font-mono text-xs text-primary hover:underline"
            >
              {nuc_id}
            </.link>
          </div>
          <p :if={(@crystal.nucleant_ids || []) == []} class="text-xs text-base-content/40">
            No constituent nucleants.
          </p>
        </div>
      </div>

      <%!-- Replay layers --%>
      <div :if={@replay_layers != []} class="mb-6">
        <h2 class="font-semibold text-sm mb-3">Replay Layers</h2>
        <div class="space-y-2">
          <div :for={{layer_key, layer_content} <- @replay_layers} class="card bg-base-200">
            <button
              class="card-body p-3 cursor-pointer w-full text-left flex items-center justify-between"
              phx-click="toggle_layer"
              phx-value-layer={layer_key}
            >
              <div class="flex items-center gap-2">
                <span class="badge badge-sm badge-accent font-mono">{layer_key}</span>
              </div>
              <span class="text-base-content/30">
                {if MapSet.member?(@expanded_layers, layer_key), do: "▼", else: "▶"}
              </span>
            </button>
            <div
              :if={MapSet.member?(@expanded_layers, layer_key)}
              class="px-4 pb-4 text-sm leading-relaxed border-t border-base-300 pt-3"
            >
              {layer_content}
            </div>
          </div>
        </div>
      </div>

      <%!-- Proofs and provenance --%>
      <div class="card bg-base-200 mb-6">
        <div class="card-body p-4">
          <h2 class="font-semibold text-sm mb-2">Provenance</h2>
          <dl class="space-y-1 text-sm">
            <div class="flex justify-between">
              <dt class="text-base-content/50">Commitment hash</dt>
              <dd class="font-mono text-xs">{@crystal.commitment_hash}</dd>
            </div>
            <div :if={(@crystal.proofs || []) != []} class="flex flex-col gap-1">
              <dt class="text-base-content/50">Proofs</dt>
              <dd :for={proof <- @crystal.proofs || []} class="font-mono text-xs">{proof}</dd>
            </div>
          </dl>
        </div>
      </div>
    </div>
    """
  end
end
