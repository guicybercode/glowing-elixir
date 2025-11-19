defmodule PhoenixLive.Storage.B2 do
  alias ExAws.S3

  @bucket_name Application.compile_env(:phoenix_live, :backblaze_bucket)

  def upload_file(file_path, filename) do
    unique_filename = "#{System.system_time(:second)}_#{filename}"

    file_path
    |> S3.Upload.stream_file()
    |> S3.upload(@bucket_name, unique_filename, acl: :public_read)
    |> ExAws.request()
    |> case do
      {:ok, _result} ->
        {:ok, "https://f002.backblazeb2.com/file/#{@bucket_name}/#{unique_filename}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete_file(filename) do
    S3.delete_object(@bucket_name, filename)
    |> ExAws.request()
  end
end
