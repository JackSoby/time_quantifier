# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TimeQuantifier.Repo.insert!(%TimeQuantifier.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
TimeQuantifier.Auth.create_user(%{
  username: "jack",
  password: "password",
  role: "admin",
  email: "sobojack@bowst.com"
})
