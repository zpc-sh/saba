defmodule Saba.Hall.FoldHandle do
  use Ash.Resource,
    otp_app: :saba,
    domain: Saba.Hall,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "saba_folds"
    repo Saba.Repo
    migrate? false
  end

  code_interface do
    define :create
    define :by_tree, args: [:tree_id]
  end

  actions do
    defaults [:read]

    create :create do
      accept [
        :id,
        :tree_id,
        :mode,
        :source_refs,
        :target_ref,
        :unfoldable,
        :commitment_hash,
        :provenance
      ]
    end

    read :by_tree do
      argument :tree_id, :string, allow_nil?: false
      filter expr(tree_id == ^arg(:tree_id))
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :tree_id, :string, allow_nil?: false

    attribute :mode, :atom,
      allow_nil?: false,
      constraints: [one_of: [:fold_back, :fold_in, :fold_over, :fold_down]]

    attribute :source_refs, {:array, :string}, default: []
    attribute :target_ref, :string
    attribute :unfoldable, :boolean, default: true
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
