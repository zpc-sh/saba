defmodule Saba.Accounts do
  use Ash.Domain, otp_app: :saba, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Saba.Accounts.Token
    resource Saba.Accounts.User
    resource Saba.Accounts.ApiKey
  end
end
