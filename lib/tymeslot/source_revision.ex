defmodule Tymeslot.SourceRevision do
  @moduledoc "Source location for the exact revision embedded at build time."

  @repository "https://github.com/pyramidal-io/Synantesis"
  @revision Application.compile_env(:tymeslot, :source_revision)

  @doc "Returns the build's source URL and whether it identifies an exact revision."
  @spec link(String.t() | nil) :: {String.t(), boolean()}
  def link(revision \\ @revision)

  def link(<<_::binary-size(40)>> = revision) do
    if Regex.match?(~r/\A[0-9a-f]{40}\z/, revision) do
      {"#{@repository}/tree/#{revision}", true}
    else
      link(nil)
    end
  end

  def link(_revision), do: {@repository, false}
end
