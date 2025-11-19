defmodule PhoenixLive.Applications do
  import Ecto.Query, warn: false
  alias PhoenixLive.Repo

  alias PhoenixLive.Applications.Application

  def list_applications do
    Repo.all(Application)
  end

  def get_application!(id), do: Repo.get!(Application, id)

  def create_application(attrs \\ %{}) do
    %Application{}
    |> Application.changeset(attrs)
    |> Repo.insert()
  end

  def update_application(%Application{} = application, attrs) do
    application
    |> Application.changeset(attrs)
    |> Repo.update()
  end

  def delete_application(%Application{} = application) do
    Repo.delete(application)
  end

  def change_application(%Application{} = application, attrs \\ %{}) do
    Application.changeset(application, attrs)
  end
end
