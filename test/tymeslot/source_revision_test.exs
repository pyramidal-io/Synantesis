defmodule Tymeslot.SourceRevisionTest do
  use ExUnit.Case, async: true

  alias Tymeslot.SourceRevision

  @repository "https://github.com/pyramidal-io/Synantesis"
  @revision "d46dfd2539d4f7c62b9e91785b052766f5c25da5"

  test "builds an immutable URL from a full commit" do
    assert SourceRevision.link(@revision) == {"#{@repository}/tree/#{@revision}", true}
  end

  test "labels builds with absent or invalid metadata as repository links" do
    for revision <- [nil, "main", String.slice(@revision, 0, 7), String.duplicate("/", 40)] do
      assert SourceRevision.link(revision) == {@repository, false}
    end
  end
end
