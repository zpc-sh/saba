defmodule Saba.Hall.Session do
  use Ash.Resource,
    otp_app: :saba,
    domain: Saba.Hall,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "saba_sessions"
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
        :title,
        :participants,
        :mode,
        :prompt_seed,
        :policies,
        :status,
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
    attribute :title, :string
    attribute :participants, {:array, :string}, default: []
    attribute :mode, :atom, default: :hangout, constraints: [one_of: [:hangout, :seminar, :heat]]
    attribute :prompt_seed, :map, default: %{}
    attribute :policies, :map, default: %{}
    attribute :status, :atom, default: :live, constraints: [one_of: [:live, :ended, :archived]]
    attribute :provenance, :map, default: %{}

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :tree, Saba.Hall.Tree,
      source_attribute: :tree_id,
      destination_attribute: :id

    has_many :moves, Saba.Hall.Move, source_attribute: :id, destination_attribute: :session_id
  end
end
