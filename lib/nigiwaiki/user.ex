defmodule Nigiwaiki.User do
  @moduledoc """
  Represents a user
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Nigiwaiki.User

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
