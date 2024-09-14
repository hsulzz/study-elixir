defmodule KV.BucketTest do
  use ExUnit.Case, async: true
  alias KV.Bucket

  setup do
    {:ok, bucket} = KV.Bucket.start_link([])
    %{bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    assert Bucket.get(bucket, "milk") == nil

    Bucket.put(bucket, "milk", 3)
    assert Bucket.get(bucket, "milk") == 3
  end

  test "test delete fun" ,%{bucket: bucket}do
    Bucket.put(bucket, "apple", 1)

    assert Bucket.delete(bucket, "apple") == 1
  end
end
