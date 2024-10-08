defmodule Crazy8Web.ErrorJSONTest do
  use Crazy8Web.ConnCase, async: true

  test "renders 404" do
    assert Crazy8Web.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert Crazy8Web.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
