defmodule PhoenixLiveWeb.AdminLive do
  use PhoenixLiveWeb, :live_view

  alias PhoenixLive.Security

  @impl true
  def mount(_params, _session, socket) do
    applications = load_applications()

    socket =
      socket
      |> assign(:applications, applications)
      |> assign(:filtered_applications, applications)
      |> assign(:search_email, "")
      |> assign(:sort_by, "submitted_at")
      |> assign(:sort_order, :desc)
      |> assign(:selected_application, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"email" => email}, socket) do
    filtered = if email == "" do
      socket.assigns.applications
    else
      Enum.filter(socket.assigns.applications, fn app ->
        String.contains?(String.downcase(app["email"]), String.downcase(email))
      end)
    end

    {:noreply, assign(socket, filtered_applications: filtered, search_email: email)}
  end

  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    current_order = socket.assigns.sort_order
    new_order = if socket.assigns.sort_by == field do
      if current_order == :asc, do: :desc, else: :asc
    else
      :desc
    end

    sorted = sort_applications(socket.assigns.filtered_applications, field, new_order)

    {:noreply, assign(socket, filtered_applications: sorted, sort_by: field, sort_order: new_order)}
  end

  @impl true
  def handle_event("view_details", %{"id" => id}, socket) do
    application = Enum.find(socket.assigns.applications, fn app ->
      app["id"] == id
    end)

    {:noreply, assign(socket, selected_application: application)}
  end

  @impl true
  def handle_event("close_details", _params, socket) do
    {:noreply, assign(socket, selected_application: nil)}
  end

  @impl true
  def handle_event("download_resume", %{"url" => url}, socket) do
    {:noreply, redirect(socket, external: url)}
  end

  @impl true
  def handle_event("logout", _params, socket) do
    {:noreply, redirect(socket, to: "/admin/logout")}
  end

  defp load_applications do
    File.mkdir_p!("applications")

    case File.ls("applications") do
      {:ok, files} ->
        files
        |> Enum.filter(fn file -> String.ends_with?(file, ".enc") end)
        |> Enum.map(fn file -> load_application_file("applications/#{file}") end)
        |> Enum.filter(&(&1 != nil))
        |> Enum.sort_by(fn app -> app["submitted_at"] end, :desc)
        |> Enum.with_index()
        |> Enum.map(fn {app, index} ->
          Map.put(app, "id", Integer.to_string(index))
        end)

      {:error, _} -> []
    end
  end

  defp load_application_file(file_path) do
    case File.read(file_path) do
      {:ok, encrypted_data} ->
        case Security.decrypt_data(encrypted_data) do
          {:ok, json_data} ->
            case Jason.decode(json_data) do
              {:ok, application} -> application
              {:error, _} -> nil
            end
          {:error, _} -> nil
        end
      {:error, _} -> nil
    end
  end

  defp sort_applications(applications, field, order) do
    Enum.sort_by(applications, fn app ->
      case field do
        "submitted_at" -> app[field]
        "email" -> String.downcase(app[field])
        "name" -> String.downcase(app[field])
        _ -> app[field]
      end
    end, order)
  end

  defp sort_indicator(field, current_field, order) do
    if field == current_field do
      if order == :asc, do: "↑", else: "↓"
    else
      ""
    end
  end

  defp format_date(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _} ->
        Calendar.strftime(datetime, "%d/%m/%Y %H:%M")
      _ ->
        datetime_string
    end
  end
end
