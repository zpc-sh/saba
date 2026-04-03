defmodule SabaWeb.SabaLive.NucleantShow do
  @moduledoc """
  Nucleant inspector — progressive replay layers from L0 (human summary)
  down to L5 (full event trace). The audience goes as deep as they choose.
  """
  use SabaWeb, :live_view

  on_mount {SabaWeb.LiveUserAuth, :live_user_optional}

  alias Saba.Sabha.SemanticNucleant

  @replay_labels %{
    "L0" => "Summary (one paragraph)",
    "L1" => "Key claims and evidence",
    "L2" => "Event trace",
    "L3" => "Full argument structure",
    "L4" => "Proof residue",
    "L5" => "Raw canonical form"
  }

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    nucleants = SemanticNucleant.by_tree!(id)

    case nucleants do
      [nucleant | _] ->
        replay_layers =
          (nucleant.replay || %{})
          |> Enum.sort_by(fn {key, _} -> key end)

        {:ok,
         assign(socket,
           page_title: "Nucleant — #{id}",
           nucleant: nucleant,
           replay_layers: replay_layers,
           expanded_layers: MapSet.new(["L0"])
         )}

      [] ->
        # Try direct ID match by searching all nucleants
        # yata: need a by_id action on SemanticNucleant
        {:ok,
         socket
         |> put_flash(:error, "Nucleant not found")
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
          <li>Nucleant</li>
        </ul>
      </div>

      <div class="mb-6">
        <h1 class="text-2xl font-bold">Nucleant</h1>
        <p class="text-xs font-mono text-base-content/40 mt-1">{@nucleant.id}</p>
      </div>

      <%!-- Cleartext: the canonical human projection --%>
      <div class="card bg-base-200 mb-6">
        <div class="card-body p-4">
          <h2 class="font-semibold text-sm mb-2">Cleartext</h2>
          <p class="text-sm leading-relaxed">{@nucleant.cleartext}</p>
        </div>
      </div>

      <%!-- Claims --%>
      <div class="card bg-base-200 mb-6">
        <div class="card-body p-4">
          <h2 class="font-semibold text-sm mb-2">Claims</h2>
          <div class="flex flex-wrap gap-2">
            <span :for={claim <- @nucleant.claims || []} class="badge badge-outline badge-sm">
              {claim}
            </span>
          </div>
        </div>
      </div>

      <%!-- Replay layers: progressive depth --%>
      <div class="mb-6">
        <h2 class="font-semibold text-sm mb-3">Replay Layers</h2>
        <p class="text-xs text-base-content/40 mb-4">
          L0 is the human-friendly summary. Each deeper layer reveals more of the discourse trace.
        </p>

        <div class="space-y-2">
          <div :for={{layer_key, layer_content} <- @replay_layers} class="card bg-base-200">
            <button
              class="card-body p-3 cursor-pointer w-full text-left flex items-center justify-between"
              phx-click="toggle_layer"
              phx-value-layer={layer_key}
            >
              <div class="flex items-center gap-2">
                <span class="badge badge-sm badge-primary font-mono">{layer_key}</span>
                <span class="text-xs text-base-content/50">{layer_label(layer_key)}</span>
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

      <%!-- Provenance --%>
      <div class="card bg-base-200 mb-6">
        <div class="card-body p-4">
          <h2 class="font-semibold text-sm mb-2">Provenance</h2>
          <dl class="space-y-1 text-sm">
            <div class="flex justify-between">
              <dt class="text-base-content/50">Commitment hash</dt>
              <dd class="font-mono text-xs">{@nucleant.commitment_hash}</dd>
            </div>
            <div :if={@nucleant.source_refs != []} class="flex flex-col gap-1">
              <dt class="text-base-content/50">Source refs</dt>
              <dd :for={ref <- @nucleant.source_refs || []} class="font-mono text-xs">{ref}</dd>
            </div>
            <div :if={@nucleant.proof_residue != []} class="flex flex-col gap-1">
              <dt class="text-base-content/50">Proof residue (move trace)</dt>
              <dd :for={ref <- @nucleant.proof_residue || []} class="font-mono text-xs">{ref}</dd>
            </div>
          </dl>
        </div>
      </div>
    </div>
    """
  end

  defp layer_label(key), do: Map.get(@replay_labels, key, "")
end
