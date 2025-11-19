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
    with {:ok, validated_params} <- validate_application_params(application_params),
         {[_ | _], []} <- {uploaded_entries(socket, :resume), "Arquivo não selecionado"} do

      [uploaded_file] = uploaded_entries(socket, :resume)

      case consume_uploaded_entry(socket, uploaded_file, &upload_resume/1) do
        {:ok, resume_url} ->
          application_data = %{
            "name" => validated_params["name"],
            "email" => validated_params["email"],
            "phone" => validated_params["phone"],
            "zip_code" => validated_params["zip_code"],
            "education" => validated_params["education"],
            "skills" => validated_params["skills"],
            "cover_letter" => validated_params["cover_letter"],
            "github_url" => validated_params["github_url"],
            "linkedin_url" => validated_params["linkedin_url"],
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
                  "✅ Candidatura enviada com sucesso! Seu currículo foi salvo e está disponível em: #{resume_url}"
                )
                |> push_navigate(to: ~p"/")

              {:noreply, socket}

            {:error, :disk_full} ->
              {:noreply, put_flash(socket, :error, "❌ Erro: Espaço em disco insuficiente. Entre em contato com o suporte.")}

            {:error, :permission_denied} ->
              {:noreply, put_flash(socket, :error, "❌ Erro: Problema de permissão no servidor. Entre em contato com o suporte.")}

            {:error, reason} ->
              {:noreply, put_flash(socket, :error, "❌ Erro ao salvar dados locais: #{format_error_reason(reason)}. Tente novamente.")}
          end

        {:error, :network_error} ->
          {:noreply, put_flash(socket, :error, "❌ Erro de conexão: Não foi possível conectar ao serviço de armazenamento. Verifique sua conexão com a internet e tente novamente.")}

        {:error, :invalid_file} ->
          {:noreply, put_flash(socket, :error, "❌ Arquivo inválido: O arquivo do currículo pode estar corrompido. Tente fazer upload de outro arquivo.")}

        {:error, :file_too_large} ->
          {:noreply, put_flash(socket, :error, "❌ Arquivo muito grande: O currículo deve ter no máximo 10MB. Reduza o tamanho do arquivo e tente novamente.")}

        {:error, :storage_quota_exceeded} ->
          {:noreply, put_flash(socket, :error, "❌ Limite de armazenamento excedido: Entre em contato com o suporte para resolver este problema.")}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "❌ Erro no upload: Não foi possível fazer upload do currículo. Tente novamente em alguns minutos.")}
      end

    else
      {:error, validation_errors} when is_list(validation_errors) ->
        error_message = "❌ Por favor, corrija os seguintes erros:\n" <>
                       Enum.map_join(validation_errors, "\n", &"• #{&1}")
        {:noreply, put_flash(socket, :error, error_message)}

      {[], _} ->
        {:noreply, put_flash(socket, :error, "❌ Arquivo obrigatório: Por favor, selecione um arquivo de currículo (PDF ou DOCX) para upload.")}
    end
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :resume, ref)}
  end

  defp validate_application_params(params) do
    errors = []

    # Campos obrigatórios
    required_fields = [
      {"name", "Nome completo"},
      {"email", "E-mail"},
      {"phone", "Telefone"},
      {"zip_code", "CEP"},
      {"education", "Formação"},
      {"skills", "Habilidades"},
      {"cover_letter", "Carta de apresentação"}
    ]

    # Validar campos obrigatórios vazios
    errors = Enum.reduce(required_fields, errors, fn {field, label}, acc ->
      case String.trim(params[field] || "") do
        "" -> ["#{label}: Campo obrigatório não pode estar vazio" | acc]
        value when byte_size(value) < 2 -> ["#{label}: Deve ter pelo menos 2 caracteres" | acc]
        _ -> acc
      end
    end)

    # Validar formato de email
    email = String.trim(params["email"] || "")
    errors = if email != "" and not String.contains?(email, "@") do
      ["E-mail: Formato de e-mail inválido (deve conter @)" | errors]
    else
      errors
    end

    # Validar telefone (formato brasileiro básico)
    phone = String.trim(params["phone"] || "")
    errors = if phone != "" and not Regex.match?(~r/^\(\d{2}\)\s\d{4,5}-\d{4}$/, phone) do
      ["Telefone: Formato inválido. Use (11) 99999-9999" | errors]
    else
      errors
    end

    # Validar CEP (formato brasileiro)
    zip_code = String.trim(params["zip_code"] || "")
    errors = if zip_code != "" and not Regex.match?(~r/^\d{5}-\d{3}$/, zip_code) do
      ["CEP: Formato inválido. Use 12345-678" | errors]
    else
      errors
    end

    # Validar tamanho mínimo da carta de apresentação
    cover_letter = String.trim(params["cover_letter"] || "")
    errors = if cover_letter != "" and String.length(cover_letter) < 50 do
      ["Carta de apresentação: Deve ter pelo menos 50 caracteres" | errors]
    else
      errors
    end

    # Validar tamanho mínimo das habilidades
    skills = String.trim(params["skills"] || "")
    errors = if skills != "" and String.length(skills) < 10 do
      ["Habilidades: Deve ter pelo menos 10 caracteres" | errors]
    else
      errors
    end

    # Validar URLs opcionais (se fornecidas)
    github_url = String.trim(params["github_url"] || "")
    errors = if github_url != "" and not String.starts_with?(github_url, "https://") do
      ["GitHub: URL deve começar com https://" | errors]
    else
      errors
    end

    linkedin_url = String.trim(params["linkedin_url"] || "")
    errors = if linkedin_url != "" and not String.starts_with?(linkedin_url, "https://") do
      ["LinkedIn: URL deve começar com https://" | errors]
    else
      errors
    end

    case errors do
      [] -> {:ok, params}
      _ -> {:error, Enum.reverse(errors)}
    end
  end

  defp upload_resume(%{path: path, client_name: filename}) do
    case B2.upload_file(path, filename) do
      {:ok, url} -> {:ok, url}
      {:error, :timeout} -> {:error, :network_error}
      {:error, :connection_failed} -> {:error, :network_error}
      {:error, :invalid_credentials} -> {:error, :network_error}
      {:error, :file_too_large} -> {:error, :file_too_large}
      {:error, :quota_exceeded} -> {:error, :storage_quota_exceeded}
      {:error, _reason} -> {:error, :upload_failed}
    end
  end

  defp error_to_string(:too_large), do: "Arquivo muito grande (máximo 10MB)"
  defp error_to_string(:not_accepted), do: "Tipo de arquivo não permitido (apenas PDF e DOCX)"
  defp error_to_string(:too_many_files), do: "Apenas um arquivo por vez"
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
        {:error, :enospc} -> {:error, :disk_full}
        {:error, :eacces} -> {:error, :permission_denied}
        {:error, :enoent} -> {:error, :permission_denied}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error ->
        # Tentar identificar o tipo de erro
        cond do
          String.contains?(inspect(error), "no space left") -> {:error, :disk_full}
          String.contains?(inspect(error), "permission") -> {:error, :permission_denied}
          true -> {:error, :unexpected_error}
        end
    end
  end

  defp format_error_reason(:disk_full), do: "espaço em disco insuficiente"
  defp format_error_reason(:permission_denied), do: "problema de permissão de arquivo"
  defp format_error_reason(:unexpected_error), do: "erro interno inesperado"
  defp format_error_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp format_error_reason(reason), do: inspect(reason)
end
