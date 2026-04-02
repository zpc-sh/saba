defmodule Saba.Sabha.Archive do
  use Ash.Resource,
    otp_app: :saba,
    domain: Saba.Sabha,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("sabha_archives")
    repo(Saba.Repo)
    migrate?(false)
  end

  attributes do
    attribute(:id, :string, primary_key?: true, allow_nil?: false)
    attribute(:tree_id, :string, allow_nil?: false)
    attribute(:tree_refs, {:array, :string}, default: [])
    attribute(:nucleant_refs, {:array, :string}, default: [])
    attribute(:crystal_refs, {:array, :string}, default: [])
    attribute(:commitments, {:array, :string}, default: [])
    attribute(:policy, :map, default: %{})
    attribute(:provenance, :map, default: %{})

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to(:tree, Saba.Sabha.Tree,
      source_attribute: :tree_id,
      destination_attribute: :id
    )
  end

  actions do
    defaults([:read])

    create :create do
      accept([
        :id,
        :tree_id,
        :tree_refs,
        :nucleant_refs,
        :crystal_refs,
        :commitments,
        :policy,
        :provenance
      ])
    end

    read :by_tree do
      argument(:tree_id, :string, allow_nil?: false)
      filter(expr(tree_id == ^arg(:tree_id)))
    end
  end

  code_interface do
    define(:create)
    define(:by_tree, args: [:tree_id])
  end
end
