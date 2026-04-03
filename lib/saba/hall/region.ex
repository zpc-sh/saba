defmodule Saba.Hall.Region do
  use Ash.Resource,
    otp_app: :saba,
    domain: Saba.Hall,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "saba_regions"
    repo Saba.Repo
    migrate? false
  end

  code_interface do
    define :create
    define :set_status
    define :by_tree, args: [:tree_id]
  end

  actions do
    defaults [:read]

    create :create do
      accept [
        :id,
        :tree_id,
        :frontier,
        :active_claims,
        :tensions,
        :metrics,
        :status,
        :commitment_hash,
        :provenance
      ]
    end

    update :set_status do
      accept [:status]
    end

    read :by_tree do
      argument :tree_id, :string, allow_nil?: false
      filter expr(tree_id == ^arg(:tree_id))
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :tree_id, :string, allow_nil?: false
    attribute :frontier, {:array, :string}, default: []
    attribute :active_claims, {:array, :string}, default: []
    attribute :tensions, {:array, :string}, default: []
    attribute :metrics, :map, default: %{}

    attribute :status, :atom,
      default: :live,
      constraints: [one_of: [:live, :collapse_ready, :overloaded, :dormant, :archived]]

    attribute :commitment_hash, :string
    attribute :provenance, :map, default: %{}

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :tree, Saba.Hall.Tree,
      source_attribute: :tree_id,
      destination_attribute: :id
  end
end
