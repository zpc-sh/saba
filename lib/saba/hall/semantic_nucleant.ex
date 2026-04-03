defmodule Saba.Hall.SemanticNucleant do
  use Ash.Resource,
    otp_app: :saba,
    domain: Saba.Hall,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "saba_nucleants"
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
        :symbol,
        :cleartext,
        :embedding,
        :claims,
        :proof_residue,
        :source_refs,
        :commitment_hash,
        :provenance,
        :replay
      ]
    end

    read :by_tree do
      argument :tree_id, :string, allow_nil?: false
      filter expr(tree_id == ^arg(:tree_id))
    end
  end

  validations do
    validate fn changeset, _context ->
      embedding = Ash.Changeset.get_attribute(changeset, :embedding)
      cleartext = Ash.Changeset.get_attribute(changeset, :cleartext)

      if is_map(embedding) and is_nil(cleartext) do
        {:error, [cleartext: "must be present when embedding is provided"]}
      else
        :ok
      end
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :tree_id, :string, allow_nil?: false
    attribute :symbol, :map, default: %{}
    attribute :cleartext, :string
    attribute :embedding, :map
    attribute :claims, {:array, :string}, default: []
    attribute :proof_residue, {:array, :string}, default: []
    attribute :source_refs, {:array, :string}, default: []
    attribute :commitment_hash, :string
    attribute :provenance, :map, default: %{}
    attribute :replay, :map, default: %{}

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :tree, Saba.Hall.Tree,
      source_attribute: :tree_id,
      destination_attribute: :id
  end
end
