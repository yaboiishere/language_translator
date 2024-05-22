defmodule LanguageTranslator.Accounts.UserTest do
  use LanguageTranslator.DataCase, async: true
  import LanguageTranslator.AccountsFixtures

  alias LanguageTranslator.Accounts.User
  alias Ecto.Changeset

  describe "make_admin/1" do
    test "makes the user an admin" do
      user = user_fixture()

      assert user.is_admin == false

      user = User.make_admin(user) |> Changeset.apply_changes()

      assert user.is_admin == true
    end
  end

  describe "get_all/2" do
    test "returns all users" do
      user_fixture()
      user_fixture()

      users = User.get_all(%{order_by: "id_asc", filter_by: nil})

      assert Enum.all?(users, fn user -> is_map(user) end)
    end

    test "returns all users with preloads" do
      user_fixture()
      user_fixture()

      users = User.get_all(%{order_by: "id_asc", filter_by: nil}, [:main_language])

      assert Enum.all?(users, fn user -> user.main_language.code end)
    end
  end

  describe "paginate_all/3" do
    test "returns paginated users" do
      user_fixture()
      user_fixture()

      pagination = %{page: 1, page_size: 1}

      %{entries: users} =
        User.paginate_all(%{order_by: "id_asc", filter_by: nil}, pagination)

      assert Enum.count(users) == 1

      pagination = %{page: 2, page_size: 1}

      %{entries: users} =
        User.paginate_all(%{order_by: "id_asc", filter_by: nil}, pagination)

      assert Enum.count(users) == 1
    end

    test "returns paginated users with preloads" do
      user_fixture()
      user_fixture()

      pagination = %{page: 1, page_size: 1}

      %{entries: users} =
        User.paginate_all(%{order_by: "id_asc", filter_by: nil}, pagination, [:main_language])

      assert Enum.all?(users, fn user -> user.main_language.code end)
    end

    test "returns paginated users ordered by username" do
      user_fixture(%{username: "test_user1"})
      user_fixture(%{username: "test_user2"})

      pagination = %{page: 1, page_size: 10}

      %{entries: users} =
        User.paginate_all(%{order_by: "username_asc", filter_by: %{"username" => ["test_user1", "test_user2"]}}, pagination)

      assert Enum.at(users, 0).username == "test_user1"
      assert Enum.at(users, 1).username == "test_user2"

      %{entries: users} =
        User.paginate_all(%{order_by: "username_desc", filter_by: %{"username" => ["test_user1", "test_user2"]}}, pagination)

      assert Enum.at(users, 0).username == "test_user2"
      assert Enum.at(users, 1).username == "test_user1"
    end

    test "returns paginated users ordered by id" do
      user_fixture()
      user_fixture()

      pagination = %{page: 1, page_size: 10}

      %{entries: users} =
        User.paginate_all(%{order_by: "id_asc", filter_by: nil}, pagination)

      assert Enum.at(users, 0).id < Enum.at(users, 1).id

      %{entries: users} =
        User.paginate_all(%{order_by: "id_desc", filter_by: nil}, pagination)

      assert Enum.at(users, 0).id > Enum.at(users, 1).id
    end

    test "returns paginated users filtered by email" do
      email1 = "test23@gmail.com"
      email2 = "test24@gmail.com"
      email3 = "notst@gmail.com"
      user_fixture(%{email: email1})
      user_fixture(%{email: email2})
      user_fixture(%{email: email3})

      pagination = %{page: 1, page_size: 10}

      %{entries: users} =
        User.paginate_all(%{order_by: "id_asc", filter_by: %{"email" => email1}}, pagination)

      assert Enum.all?(users, fn user -> user.email in [email1, email2] end)

      %{entries: users} =
        User.paginate_all(%{order_by: "id_asc", filter_by: %{"email" => "test"}}, pagination)

      assert Enum.all?(users, fn user -> String.contains?(user.email, "test") end)
    end

    test "returns paginated users filtered by id" do
      user1 = user_fixture()
      user2 = user_fixture()

      pagination = %{page: 1, page_size: 10}

      %{entries: users} =
        User.paginate_all(
          %{order_by: "id_asc", filter_by: %{"id" => [to_string(user1.id)]}},
          pagination
        )

      assert Enum.all?(users, fn user -> user.id == user1.id end)

      %{entries: users} =
        User.paginate_all(
          %{order_by: "id_asc", filter_by: %{"id" => [to_string(user1.id), to_string(user2.id)]}},
          pagination
        )

      assert Enum.all?(users, fn user -> user.id in [user1.id, user2.id] end)
    end

    test "returns paginated users filtered by username" do
      user_fixture(%{username: "test_user1"})
      user_fixture(%{username: "test_user2"})

      pagination = %{page: 1, page_size: 10}

      %{entries: users} =
        User.paginate_all(
          %{order_by: "id_asc", filter_by: %{"username" => ["test_user1"]}},
          pagination
        )

      assert Enum.all?(users, fn user -> String.contains?(user.username, "test_user") end)
    end
  end

  describe "search_username/1" do
    test "returns all users when search is empty" do
      user_fixture()
      user_fixture()

      users = User.search_username("")

      assert Enum.all?(users, fn user -> is_binary(user) end)
    end

    test "returns users that match the search" do
      user_fixture(%{username: "test_user1"})

      users = User.search_username("test_user1")

      assert Enum.all?(users, fn user -> user == "test_user1" end)
    end
  end

  describe "search_id/1" do
    test "returns users that match the search" do
      user = user_fixture()

      users = User.search_id(to_string(user.id))

      assert Enum.all?(users, fn found_user_id ->
               found_user_id |> to_string() |> String.contains?(to_string(user.id))
             end)
    end
  end
end
