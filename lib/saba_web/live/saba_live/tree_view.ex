defmodule SabaWeb.SabaLive.TreeView do
  @moduledoc """
  SVG tree visualization — renders the node tree as an interactive graph.
  Pan/zoom handled by the TreePanZoom JS hook.
  """
  use SabaWeb, :live_view

  on_mount {SabaWeb.LiveUserAuth, :live_user_optional}

  alias Saba.Sabha.{Session, Node, Move}

  # Layout constants
  @node_h_gap 200
  @node_v_gap 100

  @impl true
  def mount(%{"id" => session_id}, _session, socket) do
    case Session.by_id(session_id) do
      {:ok, session} ->
        nodes = Node.by_tree!(session.tree_id)
        moves = Move.by_session!(session.id)

        tree = build_tree(nodes)
        positioned = layout_tree(tree, nodes)

        {:ok,
         assign(socket,
           page_title: "Tree — #{session.title || "Session"}",
           session: session,
           nodes: nodes,
           moves: moves,
           positioned: positioned,
           selected_node: nil
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
  def handle_event("select_node", %{"node_id" => node_id}, socket) do
    selected = Enum.find(socket.assigns.nodes, &(&1.id == node_id))
    {:noreply, assign(socket, selected_node: selected)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto py-8 px-4">
      <%!-- Breadcrumb --%>
      <div class="text-sm breadcrumbs mb-4">
        <ul>
          <li><.link navigate={~p"/saba"}>Hall</.link></li>
          <li><.link navigate={~p"/saba/sessions/#{@session.id}"}>{@session.title || "Session"}</.link></li>
          <li>Tree</li>
        </ul>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-4 gap-4">
        <%!-- SVG tree (3/4 width) --%>
        <div class="lg:col-span-3 card bg-base-200 overflow-hidden" style="height: 600px;">
          <svg
            id="tree-svg"
            phx-hook="TreePanZoom"
            viewBox={svg_viewbox(@positioned)}
            class="w-full h-full"
            xmlns="http://www.w3.org/2000/svg"
          >
            <%!-- Edges --%>
            <line
              :for={{parent_pos, child_pos} <- tree_edges(@positioned)}
              x1={parent_pos.x}
              y1={parent_pos.y}
              x2={child_pos.x}
              y2={child_pos.y}
              stroke="currentColor"
              stroke-opacity="0.2"
              stroke-width="2"
            />

            <%!-- Nodes --%>
            <g :for={{node, pos} <- @positioned} data-node-id={node.id} class="cursor-pointer">
              <circle
                cx={pos.x}
                cy={pos.y}
                r={node_radius(node)}
                fill={node_fill(node, @selected_node)}
                stroke={node_stroke(node)}
                stroke-width="2"
                opacity={node_opacity(node)}
              />
              <text
                x={pos.x}
                y={pos.y + node_radius(node) + 16}
                text-anchor="middle"
                font-size="11"
                fill="currentColor"
                opacity="0.6"
              >
                {truncate_label(node)}
              </text>
            </g>
          </svg>
        </div>

        <%!-- Node detail panel (1/4 width) --%>
        <div class="space-y-4">
          <div :if={@selected_node} class="card bg-base-200">
            <div class="card-body p-4">
              <h3 class="font-semibold text-sm mb-2">Node</h3>
              <dl class="space-y-2 text-sm">
                <div>
                  <dt class="text-base-content/50 text-xs">ID</dt>
                  <dd class="font-mono text-xs">{@selected_node.id}</dd>
                </div>
                <div>
                  <dt class="text-base-content/50 text-xs">Status</dt>
                  <dd><span class={"badge badge-xs #{status_badge(@selected_node.status)}"}>{@selected_node.status}</span></dd>
                </div>
                <div>
                  <dt class="text-base-content/50 text-xs">Claims</dt>
                  <dd class="text-xs">{get_in(@selected_node.claims, ["text"]) || "—"}</dd>
                </div>
                <div>
                  <dt class="text-base-content/50 text-xs">Overlay (projection)</dt>
                  <dd class="text-xs italic">{get_in(@selected_node.overlays, ["text"]) || "—"}</dd>
                </div>
                <div :if={@selected_node.parent_id}>
                  <dt class="text-base-content/50 text-xs">Parent</dt>
                  <dd class="font-mono text-xs">{@selected_node.parent_id}</dd>
                </div>
              </dl>
            </div>
          </div>

          <div :if={!@selected_node} class="card bg-base-200">
            <div class="card-body p-4 text-center text-sm text-base-content/40">
              Click a node to inspect it
            </div>
          </div>

          <%!-- Legend --%>
          <div class="card bg-base-200">
            <div class="card-body p-4">
              <h3 class="font-semibold text-xs mb-2">Legend</h3>
              <div class="space-y-1">
                <div class="flex items-center gap-2 text-xs">
                  <span class="w-3 h-3 rounded-full bg-success" /> active
                </div>
                <div class="flex items-center gap-2 text-xs">
                  <span class="w-3 h-3 rounded-full bg-error" /> disputed
                </div>
                <div class="flex items-center gap-2 text-xs">
                  <span class="w-3 h-3 rounded-full bg-base-content/30" /> folded
                </div>
                <div class="flex items-center gap-2 text-xs">
                  <span class="w-3 h-3 rounded-full bg-base-content/10" /> pruned
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ── Tree layout helpers ──────────────────────────────────────────────────

  defp build_tree(nodes) do
    by_parent = Enum.group_by(nodes, & &1.parent_id)
    {by_parent, Enum.find(nodes, &is_nil(&1.parent_id))}
  end

  defp layout_tree({_by_parent, nil}, _nodes), do: []

  defp layout_tree({by_parent, root}, _nodes) do
    # Simple recursive layout: BFS with depth-based x, sibling-index-based y
    layout_subtree(by_parent, root, 0, {0})
    |> elem(0)
  end

  defp layout_subtree(by_parent, node, depth, {next_y}) do
    children = Map.get(by_parent, node.id, [])

    if children == [] do
      pos = %{x: depth * @node_h_gap + 100, y: next_y * @node_v_gap + 100}
      {[{node, pos}], {next_y + 1}}
    else
      {child_results, acc} =
        Enum.reduce(children, {[], {next_y}}, fn child, {results, y_acc} ->
          {sub_results, new_y_acc} = layout_subtree(by_parent, child, depth + 1, y_acc)
          {results ++ sub_results, new_y_acc}
        end)

      # Position this node at the vertical center of its children
      child_positions = for {_n, p} <- child_results, do: p.y
      center_y = Enum.sum(child_positions) / length(child_positions)
      pos = %{x: depth * @node_h_gap + 100, y: center_y}

      {[{node, pos} | child_results], acc}
    end
  end

  defp tree_edges(positioned) do
    pos_map = Map.new(positioned, fn {node, pos} -> {node.id, pos} end)

    for {node, child_pos} <- positioned,
        node.parent_id,
        parent_pos = Map.get(pos_map, node.parent_id),
        parent_pos != nil do
      {parent_pos, child_pos}
    end
  end

  defp svg_viewbox([]), do: "0 0 800 600"

  defp svg_viewbox(positioned) do
    xs = Enum.map(positioned, fn {_, p} -> p.x end)
    ys = Enum.map(positioned, fn {_, p} -> p.y end)
    padding = 80
    min_x = Enum.min(xs) - padding
    min_y = Enum.min(ys) - padding
    width = Enum.max(xs) - min_x + padding * 2
    height = Enum.max(ys) - min_y + padding * 2
    "#{min_x} #{min_y} #{width} #{height}"
  end

  # ── Node rendering helpers ──────────────────────────────────────────────

  defp node_radius(%{status: :folded}), do: 12
  defp node_radius(_), do: 18

  defp node_fill(%{status: :active}, selected) when not is_nil(selected), do: "oklch(0.72 0.19 142)"
  defp node_fill(%{status: :active}, _), do: "oklch(0.72 0.19 142)"
  defp node_fill(%{status: :disputed}, _), do: "oklch(0.65 0.24 18)"
  defp node_fill(%{status: :folded}, _), do: "oklch(0.55 0 0)"
  defp node_fill(%{status: :pruned}, _), do: "oklch(0.35 0 0)"
  defp node_fill(_, _), do: "oklch(0.6 0.1 250)"

  defp node_stroke(%{status: :disputed}), do: "oklch(0.55 0.24 18)"
  defp node_stroke(_), do: "transparent"

  defp node_opacity(%{status: :pruned}), do: "0.3"
  defp node_opacity(%{status: :folded}), do: "0.5"
  defp node_opacity(_), do: "1"

  defp status_badge(:active), do: "badge-success"
  defp status_badge(:disputed), do: "badge-error"
  defp status_badge(:folded), do: "badge-ghost"
  defp status_badge(:pruned), do: "badge-ghost"
  defp status_badge(_), do: "badge-ghost"

  defp truncate_label(node) do
    text = get_in(node.claims, ["text"]) || node.id
    if String.length(text) > 24, do: String.slice(text, 0, 24) <> "...", else: text
  end
end
