defmodule TimeQuantifier.Auth.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:password, :string)
    field(:username, :string)

    timestamps()
  end

  @doc false
  def changeset(%TimeQuantifier.Auth.User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :password])
    |> validate_required([:username, :password])
    |> put_pass_hash()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password: Bcrypt.hash_pwd_salt(password))
  end

  defp put_pass_hash(changeset), do: changeset
end
