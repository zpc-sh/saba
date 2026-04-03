defmodule Saba.Hall.Node do
  use Ash.Resource,
    otp_app: :saba,
    domain: Saba.Hall,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "saba_nodes"
    repo Saba.Repo
    migrate? false
  end

  code_interface do
    define :create
    define :set_status
    define :by_id, args: [:id]
    define :by_tree, args: [:tree_id]
  end

  actions do
    defaults [:read]

    create :create do
      accept [
        :id,
        :tree_id,
        :parent_id,
        :symbol,
        :claims,
        :constraints,
        :status,
        :commitment_hash,
        :provenance,
        :overlays
      ]
    end

    update :set_status do
      accept [:status]
    end

    read :by_id do
      argument :id, :string, allow_nil?: false
      get? true
      filter expr(id == ^arg(:id))
    end

    read :by_tree do
      argument :tree_id, :string, allow_nil?: false
      filter expr(tree_id == ^arg(:tree_id))
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :tree_id, :string, allow_nil?: false
    attribute :parent_id, :string

    attribute :symbol, :map, default: %{}
    attribute :claims, :map, default: %{}
    attribute :constraints, :map, default: %{}

    attribute :status, :atom,
      default: :active,
      constraints: [one_of: [:active, :folded, :unfolded, :pruned, :archived, :disputed]]

    attribute :commitment_hash, :string
    attribute :provenance, :map, default: %{}
    attribute :overlays, :map, default: %{}

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :tree, Saba.Hall.Tree,
      source_attribute: :tree_id,
      destination_attribute: :id

    belongs_to :parent_node, __MODULE__,
      source_attribute: :parent_id,
      destination_attribute: :id

    has_many :children, __MODULE__,
      source_attribute: :id,
      destination_attribute: :parent_id
  end
end
