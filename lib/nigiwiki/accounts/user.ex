defmodule Nigiwiki.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Nigiwiki.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [])
    |> validate_required([])
  end
end
