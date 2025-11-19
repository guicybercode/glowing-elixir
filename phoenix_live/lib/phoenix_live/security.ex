defmodule PhoenixLive.Security do
  @moduledoc """
  Security module for data encryption, rate limiting, and input sanitization.
  """

  # Encryption key - In production, this should come from environment variables
  @encryption_key_base "phoenix_live_secure_key_2024"
  @encryption_key :crypto.hash(:sha256, @encryption_key_base)

  # Rate limiting storage (simple in-memory, for production use Redis/ETS)
  @rate_limit_window 60_000  # 1 minute
  @rate_limit_max_requests 5  # 5 submissions per minute per IP

  def encrypt_data(data) when is_binary(data) do
    # Generate a random IV for each encryption
    iv = :crypto.strong_rand_bytes(16)

    # Encrypt using AES-256-GCM
    {ciphertext, tag} = :crypto.crypto_one_time_aead(
      :aes_256_gcm,
      @encryption_key,
      iv,
      data,
      <<>>,  # Additional authenticated data (empty)
      true   # Encrypt flag
    )

    # Combine IV + tag + ciphertext for storage
    encrypted_data = iv <> tag <> ciphertext

    # Base64 encode for safe file storage
    Base.encode64(encrypted_data)
  end

  def decrypt_data(encrypted_b64) when is_binary(encrypted_b64) do
    try do
      # Base64 decode
      encrypted_data = Base.decode64!(encrypted_b64)

      # Extract IV (16 bytes), tag (16 bytes), and ciphertext
      <<iv::binary-size(16), tag::binary-size(16), ciphertext::binary>> = encrypted_data

      # Decrypt using AES-256-GCM
      case :crypto.crypto_one_time_aead(
        :aes_256_gcm,
        @encryption_key,
        iv,
        ciphertext,
        <<>>,  # Additional authenticated data (empty)
        {tag, false}  # {tag, decrypt_flag}
      ) do
        decrypted when is_binary(decrypted) -> {:ok, decrypted}
        :error -> {:error, :decryption_failed}
      end
    rescue
      _ -> {:error, :invalid_encrypted_data}
    end
  end

  def rate_limit_check(ip_address) do
    # Simple in-memory rate limiting (for production, use a proper store)
    # This is a basic implementation - in production use Redis, ETS, or database

    current_time = System.system_time(:millisecond)
    window_start = current_time - @rate_limit_window

    # Get existing requests for this IP
    existing_requests = get_rate_limit_data(ip_address) || []

    # Filter requests within the current window
    recent_requests = Enum.filter(existing_requests, fn timestamp ->
      timestamp > window_start
    end)

    # Check if under limit
    if length(recent_requests) < @rate_limit_max_requests do
      # Add current request
      updated_requests = [current_time | recent_requests]
      put_rate_limit_data(ip_address, updated_requests)
      {:ok, length(updated_requests)}
    else
      # Rate limit exceeded
      reset_time = (List.last(recent_requests) || current_time) + @rate_limit_window
      wait_seconds = round((reset_time - current_time) / 1000)
      {:error, :rate_limit_exceeded, wait_seconds}
    end
  end

  def sanitize_input(input) when is_binary(input) do
    input
    |> String.trim()
    |> remove_html_tags()
    |> String.replace(~r/<script[^>]*>.*?<\/script>/si, "")  # Remove script tags
    |> String.replace(~r/<[^>]*>/, "")  # Remove HTML tags (fallback)
    |> String.slice(0, 10_000)  # Limit length to prevent DoS
  end

  def sanitize_input(_input), do: ""

  def validate_file_size(file_path, max_size_bytes \\ 10_000_000) do
    case File.stat(file_path) do
      {:ok, %File.Stat{size: size}} when size > max_size_bytes ->
        {:error, :file_too_large, size}
      {:ok, %File.Stat{size: size}} ->
        {:ok, size}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def generate_csrf_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64()
  end

  def validate_csrf_token(token) when is_binary(token) do
    # Basic validation - check if it's a valid base64 string
    case Base.url_decode64(token) do
      {:ok, decoded} when byte_size(decoded) == 32 -> true
      _ -> false
    end
  end

  def validate_csrf_token(_), do: false

  # Private functions for rate limiting storage
  # In production, replace with proper persistent storage

  @rate_limit_table :rate_limit_data

  defp get_rate_limit_data(ip) do
    # Initialize ETS table if not exists
    case :ets.info(@rate_limit_table) do
      :undefined ->
        :ets.new(@rate_limit_table, [:named_table, :public, :set])
        nil
      _ ->
        case :ets.lookup(@rate_limit_table, ip) do
          [{^ip, data}] -> data
          [] -> nil
        end
    end
  end

  defp put_rate_limit_data(ip, data) do
    :ets.insert(@rate_limit_table, {ip, data})
  end

  # Simple HTML tag removal - strips dangerous HTML/XSS content
  defp remove_html_tags(input) do
    # Remove script tags and their content
    input = Regex.replace(~r/<script[^>]*>.*?<\/script>/si, input, "")

    # Remove style tags and their content
    input = Regex.replace(~r/<style[^>]*>.*?<\/style>/si, input, "")

    # Remove event handlers (onclick, onload, etc.)
    input = Regex.replace(~r/\bon\w+="[^"]*"/i, input, "")
    input = Regex.replace(~r/\bon\w+='[^']*'/i, input, "")

    # Remove javascript: URLs
    input = Regex.replace(~r/javascript:[^"'\s]*/i, input, "")

    # Remove dangerous attributes
    input = Regex.replace(~r/\s+(href|src)=["'][^"']*["']/i, input, "")

    # Basic HTML tag removal
    Regex.replace(~r/<[^>]+>/, input, "")
  end
end
