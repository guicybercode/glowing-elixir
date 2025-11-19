defmodule PhoenixLiveWeb.ApplicationLive do
  use PhoenixLiveWeb, :live_view

  alias PhoenixLive.Storage.B2
  alias PhoenixLive.Security

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(form: to_form(%{}))
      |> assign(:error_to_string, &error_to_string/1)
      |> assign(:loading, true)
      |> assign(:upload_progress, 0)
      |> assign(:processing, false)
      |> assign(:admin_click_count, 0)
      |> allow_upload(:resume,
        accept: ~w(.pdf .docx),
        max_entries: 1,
        max_file_size: 10_000_000
      )

    # Simular loading inicial por 1 segundo
    Process.send_after(self(), :initial_load_complete, 1000)

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"application" => application_params}, socket) do
    # Rate limiting check
    ip_address = get_connect_info(socket, :peer_data).address
                 |> :inet.ntoa()
                 |> List.to_string()

    case Security.rate_limit_check(ip_address) do
      {:ok, _request_count} ->
        socket = socket
                  |> assign(:processing, true)
                  |> assign(:upload_progress, 10)

        # Sanitize inputs
        sanitized_params = sanitize_application_params(application_params)

        with {:ok, validated_params} <- validate_application_params(sanitized_params),
             [uploaded_file | _] <- uploaded_entries(socket, :resume) do
          send(self(), {:upload_progress, 50})

          case consume_uploaded_entry(socket, uploaded_file, &upload_resume/1) do
            {:ok, resume_url} ->
              send(self(), {:upload_progress, 75})

              raw_application_data = %{
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

              case validate_application_data(raw_application_data) do
                {:ok, application_data} ->
                  case save_application_data(application_data) do
                    :ok ->
                      send(self(), {:upload_progress, 100})
                      Process.send_after(self(), :processing_complete, 500)

                      socket =
                        socket
                        |> put_flash(
                          :info,
                          "✅ Candidatura enviada com sucesso! Seu currículo foi salvo e está disponível em: #{resume_url}"
                        )
                        |> push_navigate(to: ~p"/")

                      {:noreply, socket}

                    {:error, :disk_full} ->
                      {:noreply,
                       put_flash(
                         socket,
                         :error,
                         "❌ Erro: Espaço em disco insuficiente. Entre em contato com o suporte."
                       )}

                    {:error, :permission_denied} ->
                      {:noreply,
                       put_flash(
                         socket,
                         :error,
                         "❌ Erro: Problema de permissão no servidor. Entre em contato com o suporte."
                       )}

                    {:error, reason} ->
                      {:noreply,
                       put_flash(
                         socket,
                         :error,
                         "❌ Erro ao salvar dados locais: #{format_error_reason(reason)}. Tente novamente."
                       )}
                  end

                {:error, validation_errors} ->
                  error_message =
                    "❌ Validação backend falhou:\n" <>
                      Enum.map_join(validation_errors, "\n", &"• #{&1}")

                  {:noreply, put_flash(socket, :error, error_message)}
              end

            {:error, :network_error} ->
              {:noreply,
               put_flash(
                 socket,
                 :error,
                 "❌ Erro de conexão: Não foi possível conectar ao serviço de armazenamento. Verifique sua conexão com a internet e tente novamente."
               )}

            {:error, :invalid_file} ->
              {:noreply,
               put_flash(
                 socket,
                 :error,
                 "❌ Arquivo inválido: O arquivo do currículo pode estar corrompido. Tente fazer upload de outro arquivo."
               )}

            {:error, :file_too_large} ->
              {:noreply,
               put_flash(
                 socket,
                 :error,
                 "❌ Arquivo muito grande: O currículo deve ter no máximo 10MB. Reduza o tamanho do arquivo e tente novamente."
               )}

            {:error, :storage_quota_exceeded} ->
              {:noreply,
               put_flash(
                 socket,
                 :error,
                 "❌ Limite de armazenamento excedido: Entre em contato com o suporte para resolver este problema."
               )}

            {:error, _reason} ->
              {:noreply,
               put_flash(
                 socket,
                 :error,
                 "❌ Erro no upload: Não foi possível fazer upload do currículo. Tente novamente em alguns minutos."
               )}
          end
        else
          {:error, validation_errors} when is_list(validation_errors) ->
            error_message =
              "❌ Por favor, corrija os seguintes erros:\n" <>
                Enum.map_join(validation_errors, "\n", &"• #{&1}")

            {:noreply, put_flash(socket, :error, error_message)}

          [] ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "❌ Arquivo obrigatório: Por favor, selecione um arquivo de currículo (PDF ou DOCX) para upload."
             )}

          _ ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "❌ Erro: Arquivo não selecionado. Por favor, selecione um arquivo de currículo."
             )}
        end

      {:error, :rate_limit_exceeded, wait_seconds} ->
        {:noreply, put_flash(socket, :error, "❌ Muitas tentativas. Aguarde #{wait_seconds} segundos antes de tentar novamente.")}
    end
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :resume, ref)}
  end

  @impl true
  def handle_event("admin_access", _params, socket) do
    current_count = socket.assigns.admin_click_count
    new_count = current_count + 1

    if new_count >= 3 do
      # Redirecionar para admin após 3 cliques
      {:noreply, redirect(socket, to: "/admin/login")}
    else
      # Resetar contador após 2 segundos sem clique
      Process.send_after(self(), :reset_admin_clicks, 2000)
      {:noreply, assign(socket, admin_click_count: new_count)}
    end
  end

  @impl true
  def handle_event("hide_admin_trigger", _params, socket) do
    {:noreply, assign(socket, admin_click_count: 0)}
  end

  defp sanitize_application_params(params) do
    %{
      "name" => Security.sanitize_input(params["name"]),
      "email" => Security.sanitize_input(params["email"]),
      "phone" => Security.sanitize_input(params["phone"]),
      "zip_code" => Security.sanitize_input(params["zip_code"]),
      "education" => Security.sanitize_input(params["education"]),
      "skills" => Security.sanitize_input(params["skills"]),
      "cover_letter" => Security.sanitize_input(params["cover_letter"]),
      "github_url" => Security.sanitize_input(params["github_url"]),
      "linkedin_url" => Security.sanitize_input(params["linkedin_url"])
    }
  end

  @impl true
  def handle_info(:initial_load_complete, socket) do
    {:noreply, assign(socket, :loading, false)}
  end

  @impl true
  def handle_info({:upload_progress, progress}, socket) do
    {:noreply, assign(socket, :upload_progress, progress)}
  end

  @impl true
  def handle_info(:processing_complete, socket) do
    {:noreply, assign(socket, :processing, false)}
  end

  @impl true
  def handle_info(:reset_admin_clicks, socket) do
    {:noreply, assign(socket, :admin_click_count, 0)}
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
    errors =
      Enum.reduce(required_fields, errors, fn {field, label}, acc ->
        case String.trim(params[field] || "") do
          "" -> ["#{label}: Campo obrigatório não pode estar vazio" | acc]
          value when byte_size(value) < 2 -> ["#{label}: Deve ter pelo menos 2 caracteres" | acc]
          _ -> acc
        end
      end)

    # Validar formato de email
    email = String.trim(params["email"] || "")

    errors =
      if email != "" and not String.contains?(email, "@") do
        ["E-mail: Formato de e-mail inválido (deve conter @)" | errors]
      else
        errors
      end

    # Validar telefone (formato brasileiro básico)
    phone = String.trim(params["phone"] || "")

    errors =
      if phone != "" and not Regex.match?(~r/^\(\d{2}\)\s\d{4,5}-\d{4}$/, phone) do
        ["Telefone: Formato inválido. Use (11) 99999-9999" | errors]
      else
        errors
      end

    # Validar CEP (formato brasileiro)
    zip_code = String.trim(params["zip_code"] || "")

    errors =
      if zip_code != "" and not Regex.match?(~r/^\d{5}-\d{3}$/, zip_code) do
        ["CEP: Formato inválido. Use 12345-678" | errors]
      else
        errors
      end

    # Validar tamanho mínimo da carta de apresentação
    cover_letter = String.trim(params["cover_letter"] || "")

    errors =
      if cover_letter != "" and String.length(cover_letter) < 50 do
        ["Carta de apresentação: Deve ter pelo menos 50 caracteres" | errors]
      else
        errors
      end

    # Validar tamanho mínimo das habilidades
    skills = String.trim(params["skills"] || "")

    errors =
      if skills != "" and String.length(skills) < 10 do
        ["Habilidades: Deve ter pelo menos 10 caracteres" | errors]
      else
        errors
      end

    # Validar URLs opcionais (se fornecidas)
    github_url = String.trim(params["github_url"] || "")

    errors =
      if github_url != "" and not String.starts_with?(github_url, "https://") do
        ["GitHub: URL deve começar com https://" | errors]
      else
        errors
      end

    linkedin_url = String.trim(params["linkedin_url"] || "")

    errors =
      if linkedin_url != "" and not String.starts_with?(linkedin_url, "https://") do
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
      filename = "applications/#{timestamp}_#{email_clean}.enc"

      File.mkdir_p!("applications")

      # Convert to JSON and encrypt
      json_data = Jason.encode!(data, pretty: true)
      encrypted_data = Security.encrypt_data(json_data)

      case File.write(filename, encrypted_data) do
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

  defp validate_application_data(data) do
    errors = []

    # Validações rigorosas de backend

    # Campos obrigatórios não podem ser nil ou strings vazias
    required_fields = [
      {"name", "Nome completo"},
      {"email", "E-mail"},
      {"phone", "Telefone"},
      {"zip_code", "CEP"},
      {"education", "Formação"},
      {"skills", "Habilidades"},
      {"cover_letter", "Carta de apresentação"},
      {"resume_url", "URL do currículo"},
      {"resume_filename", "Nome do arquivo do currículo"}
    ]

    errors =
      Enum.reduce(required_fields, errors, fn {field, label}, acc ->
        value = data[field]

        cond do
          is_nil(value) -> ["#{label}: Campo obrigatório não pode ser nulo" | acc]
          not is_binary(value) -> ["#{label}: Deve ser uma string válida" | acc]
          String.trim(value) == "" -> ["#{label}: Campo obrigatório não pode estar vazio" | acc]
          true -> acc
        end
      end)

    # Validação rigorosa de email
    email = data["email"]

    errors =
      if is_binary(email) and String.trim(email) != "" do
        email = String.trim(email)

        cond do
          not String.contains?(email, "@") ->
            ["E-mail: Deve conter @" | errors]

          String.length(email) < 5 ->
            ["E-mail: Muito curto" | errors]

          String.length(email) > 254 ->
            ["E-mail: Muito longo" | errors]

          not Regex.match?(~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, email) ->
            ["E-mail: Formato inválido" | errors]

          true ->
            errors
        end
      else
        errors
      end

    # Validação rigorosa de telefone brasileiro
    phone = data["phone"]

    errors =
      if is_binary(phone) and String.trim(phone) != "" do
        phone = String.trim(phone)
        # Remove todos os caracteres não numéricos para contar dígitos
        digits_only = String.replace(phone, ~r/\D/, "")

        cond do
          not Regex.match?(~r/^\(\d{2}\)\s\d{4,5}-\d{4}$/, phone) ->
            ["Telefone: Formato deve ser (XX) XXXXX-XXXX" | errors]

          String.length(digits_only) < 10 ->
            ["Telefone: Deve ter pelo menos 10 dígitos" | errors]

          String.length(digits_only) > 11 ->
            ["Telefone: Deve ter no máximo 11 dígitos" | errors]

          true ->
            errors
        end
      else
        errors
      end

    # Validação rigorosa de CEP brasileiro
    zip_code = data["zip_code"]

    errors =
      if is_binary(zip_code) and String.trim(zip_code) != "" do
        zip_code = String.trim(zip_code)
        digits_only = String.replace(zip_code, ~r/\D/, "")

        cond do
          not Regex.match?(~r/^\d{5}-\d{3}$/, zip_code) ->
            ["CEP: Formato deve ser XXXXX-XXX" | errors]

          String.length(digits_only) != 8 ->
            ["CEP: Deve ter exatamente 8 dígitos" | errors]

          true ->
            errors
        end
      else
        errors
      end

    # Validação de tamanho mínimo e máximo para texto
    text_validations = [
      {"education", "Formação", 3, 200},
      {"skills", "Habilidades", 10, 1000},
      {"cover_letter", "Carta de apresentação", 50, 2000}
    ]

    errors =
      Enum.reduce(text_validations, errors, fn {field, label, min_len, max_len}, acc ->
        value = data[field]

        if is_binary(value) and String.trim(value) != "" do
          len = String.length(String.trim(value))

          cond do
            len < min_len ->
              ["#{label}: Deve ter pelo menos #{min_len} caracteres (atual: #{len})" | acc]

            len > max_len ->
              ["#{label}: Deve ter no máximo #{max_len} caracteres (atual: #{len})" | acc]

            true ->
              acc
          end
        else
          acc
        end
      end)

    # Validação de URLs opcionais (se fornecidas)
    url_fields = [
      {"github_url", "GitHub"},
      {"linkedin_url", "LinkedIn"}
    ]

    errors =
      Enum.reduce(url_fields, errors, fn {field, label}, acc ->
        value = data[field]

        if is_binary(value) and String.trim(value) != "" do
          url = String.trim(value)

          cond do
            not String.starts_with?(url, "https://") ->
              ["#{label}: URL deve começar com https://" | acc]

            String.length(url) < 12 ->
              ["#{label}: URL muito curta" | acc]

            String.length(url) > 500 ->
              ["#{label}: URL muito longa" | acc]

            not Regex.match?(~r/^https:\/\/[^\s\/$.?#].[^\s]*$/i, url) ->
              ["#{label}: Formato de URL inválido" | acc]

            true ->
              acc
          end
        else
          acc
        end
      end)

    # Validação da URL do currículo
    resume_url = data["resume_url"]

    errors =
      if is_binary(resume_url) and String.trim(resume_url) != "" do
        cond do
          not String.starts_with?(resume_url, "https://") ->
            ["URL do currículo: Deve começar com https://" | errors]

          not String.contains?(resume_url, "backblazeb2.com") ->
            ["URL do currículo: Deve ser uma URL válida do Backblaze B2" | errors]

          String.length(resume_url) < 20 ->
            ["URL do currículo: URL muito curta" | errors]

          true ->
            errors
        end
      else
        errors
      end

    # Validação do nome do arquivo do currículo
    resume_filename = data["resume_filename"]

    errors =
      if is_binary(resume_filename) and String.trim(resume_filename) != "" do
        cond do
          String.length(resume_filename) < 5 ->
            ["Nome do arquivo: Nome muito curto" | errors]

          String.length(resume_filename) > 255 ->
            ["Nome do arquivo: Nome muito longo" | errors]

          not (String.ends_with?(resume_filename, ".pdf") or
                   String.ends_with?(resume_filename, ".docx")) ->
            ["Nome do arquivo: Deve ser PDF ou DOCX" | errors]

          String.contains?(resume_filename, "..") ->
            ["Nome do arquivo: Nome inválido (contém ..)" | errors]

          String.contains?(resume_filename, "/") or String.contains?(resume_filename, "\\") ->
            ["Nome do arquivo: Nome inválido (contém separadores de caminho)" | errors]

          true ->
            errors
        end
      else
        errors
      end

    # Validação do timestamp de submissão
    submitted_at = data["submitted_at"]

    errors =
      if is_binary(submitted_at) and String.trim(submitted_at) != "" do
        case DateTime.from_iso8601(submitted_at) do
          {:ok, _datetime, _} -> errors
          _ -> ["Data de submissão: Formato de data inválido" | errors]
        end
      else
        ["Data de submissão: Campo obrigatório" | errors]
      end

    # Validação final: sanitizar dados
    sanitized_data = %{
      "name" => String.trim(data["name"]),
      "email" => String.downcase(String.trim(data["email"])),
      "phone" => String.trim(data["phone"]),
      "zip_code" => String.trim(data["zip_code"]),
      "education" => String.trim(data["education"]),
      "skills" => String.trim(data["skills"]),
      "cover_letter" => String.trim(data["cover_letter"]),
      "github_url" => if(data["github_url"], do: String.trim(data["github_url"]), else: nil),
      "linkedin_url" =>
        if(data["linkedin_url"], do: String.trim(data["linkedin_url"]), else: nil),
      "resume_url" => String.trim(data["resume_url"]),
      "resume_filename" => String.trim(data["resume_filename"]),
      "submitted_at" => data["submitted_at"]
    }

    case errors do
      [] -> {:ok, sanitized_data}
      _ -> {:error, Enum.reverse(errors)}
    end
  end
end
