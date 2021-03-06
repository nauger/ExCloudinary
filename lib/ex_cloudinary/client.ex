defmodule ExCloudinary.Client do
  @moduledoc false
  use HTTPoison.Base
  @base_url ~S(https://api.cloudinary.com/v1_1)
  @signed_params ~w(callback eager format from_public_id public_id tags timestamp to_public_id text transformation type)a

  ## HTTPoison.Base extensions

  @doc false
  def process_url(url), do: "#{@base_url}/#{get_name}/#{url}"

  @doc false
  def process_request_body(body) do
    body
    |> Keyword.merge([api_key: get_api_key, timestamp: get_timestamp])
    |> sign_body()
    |> multipart_encode()
  end

  @doc false
  def process_response_body(body), do: Poison.decode!(body)

  ## Private helpers

  defp get_name, do: Application.get_env(:ex_cloudinary, :name)

  defp get_api_key, do: Application.get_env(:ex_cloudinary, :api_key)

  defp get_api_secret, do: Application.get_env(:ex_cloudinary, :api_secret)

  defp get_timestamp, do: :os.system_time(:seconds) |> Integer.to_string()

  defp sign_body(body) do
    body
    |> generate_signature()
    |> add_signature_to_body(body)
  end

  defp generate_signature(body) do
    body
    |> Keyword.take(@signed_params)
    |> List.keysort(0)
    |> join_query()
    |> append_secret()
    |> hash_signature()
    |> Base.encode16()
  end

  defp join_query(params) do
    Enum.map_join(params, "&", fn {k, v} -> "#{k}=#{v}" end)
  end

  defp append_secret(signature), do: signature <> get_api_secret

  defp hash_signature(signature), do: :crypto.hash(:sha, signature)

  defp add_signature_to_body(signature, body), do: Keyword.put(body, :signature, signature)

  defp multipart_encode(body) do
    body = Enum.map(body, fn {:file, path} -> {:file, path}
                              {key, value} -> {to_string(key), value} end)
    {:multipart, body}
  end
end
