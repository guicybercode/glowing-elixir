defmodule PhoenixLive.Storage.B2 do
  alias ExAws.S3

  @bucket_name Application.compile_env(:phoenix_live, :backblaze_bucket)

  def upload_file(file_path, filename) do
    unique_filename = "#{System.system_time(:second)}_#{filename}"

    case File.stat(file_path) do
      {:ok, %File.Stat{size: size}} when size > 10_000_000 ->
        {:error, :file_too_large}

      {:ok, _} ->
        file_path
        |> S3.Upload.stream_file()
        |> S3.upload(@bucket_name, unique_filename, acl: :public_read)
        |> ExAws.request()
        |> case do
          {:ok, _result} ->
            {:ok, "https://f002.backblazeb2.com/file/#{@bucket_name}/#{unique_filename}"}

          {:error, {:http_error, 403, _}} ->
            {:error, :invalid_credentials}

          {:error, {:http_error, 507, _}} ->
            {:error, :quota_exceeded}

          {:error, {:http_error, status, _}} when status >= 500 ->
            {:error, :connection_failed}

          {:error, {:http_error, status, _}} when status >= 400 ->
            {:error, :invalid_file}

          {:error, :timeout} ->
            {:error, :timeout}

          {:error, :nxdomain} ->
            {:error, :connection_failed}

          {:error, :econnrefused} ->
            {:error, :connection_failed}

          {:error, reason} ->
            # Verificar se é erro de rede baseado na mensagem
            error_str = inspect(reason)
            cond do
              String.contains?(error_str, "timeout") -> {:error, :timeout}
              String.contains?(error_str, "connection") -> {:error, :connection_failed}
              String.contains?(error_str, "network") -> {:error, :connection_failed}
              String.contains?(error_str, "dns") -> {:error, :connection_failed}
              true -> {:error, :upload_failed}
            end
        end

      {:error, :enoent} ->
        {:error, :invalid_file}

      {:error, _} ->
        {:error, :invalid_file}
    end
  end

  def delete_file(filename) do
    S3.delete_object(@bucket_name, filename)
    |> ExAws.request()
  end
end
