defmodule PhoenixLiveWeb.ApplicationLive do
  use PhoenixLiveWeb, :live_view

  alias PhoenixLive.Storage.B2

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(form: to_form(%{}))
      |> allow_upload(:resume,
        accept: ~w(.pdf .docx),
        max_entries: 1,
        max_file_size: 10_000_000
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"application" => application_params}, socket) do
    case uploaded_entries(socket, :resume) do
      {[_ | _], []} ->
        [uploaded_file] = uploaded_entries(socket, :resume)

        case consume_uploaded_entry(socket, uploaded_file, &upload_resume/1) do
          {:ok, resume_url} ->
            application_data = %{
              "name" => application_params["name"],
              "email" => application_params["email"],
              "phone" => application_params["phone"],
              "zip_code" => application_params["zip_code"],
              "education" => application_params["education"],
              "skills" => application_params["skills"],
              "cover_letter" => application_params["cover_letter"],
              "github_url" => application_params["github_url"],
              "linkedin_url" => application_params["linkedin_url"],
              "resume_url" => resume_url,
              "resume_filename" => uploaded_file.client_name,
              "submitted_at" => DateTime.utc_now() |> DateTime.to_iso8601()
            }

            case save_application_data(application_data) do
              :ok ->
                socket =
                  socket
                  |> put_flash(
                    :info,
                    "Candidatura enviada com sucesso! Dados salvos e currículo enviado para: #{resume_url}"
                  )
                  |> push_navigate(to: ~p"/")

                {:noreply, socket}

              {:error, reason} ->
                socket =
                  socket
                  |> put_flash(:error, "Erro ao salvar dados: #{reason}. Tente novamente.")

                {:noreply, socket}
            end

          {:error, _reason} ->
            socket =
              socket
              |> put_flash(:error, "Erro ao fazer upload do currículo. Tente novamente.")

            {:noreply, socket}
        end

      _ ->
        socket =
          socket
          |> put_flash(:error, "Por favor, selecione um arquivo para upload.")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :resume, ref)}
  end

  defp upload_resume(%{path: path, client_name: filename}) do
    case B2.upload_file(path, filename) do
      {:ok, url} -> {:ok, url}
      {:error, _reason} -> {:error, :upload_failed}
    end
  end

  defp error_to_string(:too_large), do: "Arquivo muito grande"
  defp error_to_string(:not_accepted), do: "Tipo de arquivo não permitido"
  defp error_to_string(:too_many_files), do: "Muitos arquivos selecionados"
  defp error_to_string(_), do: "Erro no upload do arquivo"

  defp save_application_data(data) do
    try do
      timestamp = DateTime.utc_now() |> DateTime.to_unix()
      email_clean = String.replace(data["email"], "@", "_at_")
      filename = "applications/#{timestamp}_#{email_clean}.json"

      File.mkdir_p!("applications")

      json_data = Jason.encode!(data, pretty: true)

      case File.write(filename, json_data) do
        :ok -> :ok
        {:error, reason} -> {:error, "Erro ao salvar arquivo: #{reason}"}
      end
    rescue
      error -> {:error, "Erro inesperado: #{inspect(error)}"}
    end
  end
end
