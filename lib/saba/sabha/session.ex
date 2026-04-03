defmodule Saba.Sabha.Session do
  use Ash.Resource,
    otp_app: :saba,
    domain: Saba.Sabha,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("sabha_sessions")
    repo(Saba.Repo)
    migrate?(false)
  end

  attributes do
    attribute(:id, :string, primary_key?: true, allow_nil?: false)
    attribute(:tree_id, :string, allow_nil?: false)
    attribute(:title, :string)
    attribute(:participants, {:array, :string}, default: [])
    attribute(:mode, :atom, default: :hangout, constraints: [one_of: [:hangout, :seminar, :heat]])
    attribute(:prompt_seed, :map, default: %{})
    attribute(:policies, :map, default: %{})
    attribute(:status, :atom, default: :live, constraints: [one_of: [:live, :ended, :archived]])
    attribute(:provenance, :map, default: %{})

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to(:tree, Saba.Sabha.Tree,
      source_attribute: :tree_id,
      destination_attribute: :id
    )

    has_many(:moves, Saba.Sabha.Move, source_attribute: :id, destination_attribute: :session_id)
  end

  actions do
    defaults([:read])

    create :create do
      accept([
        :id,
        :tree_id,
        :title,
        :participants,
        :mode,
        :prompt_seed,
        :policies,
        :status,
        :provenance
      ])
    end

    update :set_status do
      accept([:status])
    end

    read :by_tree do
      argument(:tree_id, :string, allow_nil?: false)
      filter(expr(tree_id == ^arg(:tree_id)))
    end

    read :list_live do
      filter(expr(status == :live))
    end

    read :list_ended do
      filter(expr(status == :ended))
    end

    read :list_archived do
      filter(expr(status == :archived))
    end

    read :by_id do
      argument(:id, :string, allow_nil?: false)
      get?(true)
      filter(expr(id == ^arg(:id)))
    end
  end

  code_interface do
    define(:create)
    define(:set_status)
    define(:by_tree, args: [:tree_id])
    define(:list_live)
    define(:list_ended)
    define(:list_archived)
    define(:by_id, args: [:id])
  end
end
