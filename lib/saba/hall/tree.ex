defmodule Saba.Hall.Tree do
  use Ash.Resource,
    otp_app: :saba,
    domain: Saba.Hall,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "saba_trees"
    repo Saba.Repo
    migrate? false
  end

  code_interface do
    define :create
    define :set_status
    define :by_id, args: [:id]
  end

  actions do
    defaults [:read]

    create :create do
      accept [:id, :root_node_id, :status, :policy, :metadata, :commitment_hash, :provenance]
    end

    update :set_status do
      accept [:status]
    end

    read :by_id do
      argument :id, :string, allow_nil?: false
      get? true
      filter expr(id == ^arg(:id))
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :root_node_id, :string

    attribute :status, :atom,
      default: :live,
      constraints: [one_of: [:live, :archived, :restarted]]

    attribute :policy, :map, default: %{}
    attribute :metadata, :map, default: %{}
    attribute :commitment_hash, :string
    attribute :provenance, :map, default: %{}

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :nodes, Saba.Hall.Node, source_attribute: :id, destination_attribute: :tree_id
    has_many :regions, Saba.Hall.Region, source_attribute: :id, destination_attribute: :tree_id
    has_many :branches, Saba.Hall.Branch, source_attribute: :id, destination_attribute: :tree_id
    has_many :sessions, Saba.Hall.Session, source_attribute: :id, destination_attribute: :tree_id
    has_many :moves, Saba.Hall.Move, source_attribute: :id, destination_attribute: :tree_id
    has_many :folds, Saba.Hall.FoldHandle, source_attribute: :id, destination_attribute: :tree_id
    has_many :archives, Saba.Hall.Archive, source_attribute: :id, destination_attribute: :tree_id

    has_many :nucleants, Saba.Hall.SemanticNucleant,
      source_attribute: :id,
      destination_attribute: :tree_id

    has_many :crystals, Saba.Hall.Crystal, source_attribute: :id, destination_attribute: :tree_id
  end
end
