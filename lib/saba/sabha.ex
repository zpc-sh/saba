defmodule Saba.Sabha do
  @moduledoc """
  Ash domain scaffolding for conversational computing v2 (Sabha profile).

  This domain is intentionally thin and focuses on canonical substrate and
  artifact resources that can be evolved independently in Merkin Tree/Saba.
  """

  use Ash.Domain, otp_app: :saba

  resources do
    resource(Saba.Sabha.Tree)
    resource(Saba.Sabha.Node)
    resource(Saba.Sabha.Region)
    resource(Saba.Sabha.Branch)
    resource(Saba.Sabha.Session)
    resource(Saba.Sabha.Move)
    resource(Saba.Sabha.FoldHandle)
    resource(Saba.Sabha.Archive)
    resource(Saba.Sabha.SemanticNucleant)
    resource(Saba.Sabha.Crystal)
  end
end
