defmodule Saba.Hall do
  @moduledoc """
  Ash domain scaffolding for conversational computing v2 (Saba hall profile).

  This domain is intentionally thin and focuses on canonical substrate and
  artifact resources that can be evolved independently in Merkin Tree/Saba hall.
  """

  use Ash.Domain, otp_app: :saba

  resources do
    resource Saba.Hall.Tree
    resource Saba.Hall.Node
    resource Saba.Hall.Region
    resource Saba.Hall.Branch
    resource Saba.Hall.Session
    resource Saba.Hall.Move
    resource Saba.Hall.FoldHandle
    resource Saba.Hall.Archive
    resource Saba.Hall.SemanticNucleant
    resource Saba.Hall.Crystal
  end
end
