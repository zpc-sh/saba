defmodule Saba.Sabha.Move do
  use Ash.Resource,
    otp_app: :saba,
    domain: Saba.Sabha,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("sabha_moves")
    repo(Saba.Repo)
    migrate?(false)
  end

  @move_types [
    :assert,
    :challenge,
    :clarify,
    :concede,
    :reframe,
    :fork,
    :fold,
    :unfold,
    :collapse,
    :crystallize,
    :prune,
    :archive,
    :rehydrate
  ]

  attributes do
    attribute(:id, :string, primary_key?: true, allow_nil?: false)
    attribute(:session_id, :string, allow_nil?: false)
    attribute(:tree_id, :string, allow_nil?: false)
    attribute(:actor_id, :string, allow_nil?: false)
    attribute(:type, :atom, allow_nil?: false, constraints: [one_of: @move_types])
    attribute(:target_ref, :string)
    attribute(:payload, :map, default: %{})
    attribute(:result_refs, {:array, :string}, default: [])
    attribute(:commitment_hash, :string)
    attribute(:provenance, :map, default: %{})

    create_timestamp(:inserted_at)
  end

  relationships do
    belongs_to(:tree, Saba.Sabha.Tree,
      source_attribute: :tree_id,
      destination_attribute: :id
    )

    belongs_to(:session, Saba.Sabha.Session,
      source_attribute: :session_id,
      destination_attribute: :id
    )
  end

  actions do
    defaults([:read])

    create :create do
      accept([
        :id,
        :session_id,
        :tree_id,
        :actor_id,
        :type,
        :target_ref,
        :payload,
        :result_refs,
        :commitment_hash,
        :provenance
      ])
    end

    read :by_session do
      argument(:session_id, :string, allow_nil?: false)
      filter(expr(session_id == ^arg(:session_id)))
    end

    read :by_tree do
      argument(:tree_id, :string, allow_nil?: false)
      filter(expr(tree_id == ^arg(:tree_id)))
    end
  end

  code_interface do
    define(:create)
    define(:by_session, args: [:session_id])
    define(:by_tree, args: [:tree_id])
  end
end
