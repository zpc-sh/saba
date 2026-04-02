defmodule Saba.Ledger do
  use Ash.Domain,
    otp_app: :saba

  resources do
    resource Saba.Ledger.Account
    resource Saba.Ledger.Balance
    resource Saba.Ledger.Transfer
  end
end
