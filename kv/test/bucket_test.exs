defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  # Version 1
  test "V1: stores values by key" do
    {:ok, bucket} = KV.Bucket.start_link([])
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end

  # Version 2
  setup do
    {:ok, bucket} = KV.Bucket.start_link([])
    %{bucket: bucket}
  end

  test "V2: stores values by key", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end

  test "delete values by key", %{bucket: bucket} do
    alias KV.Bucket
    Bucket.put(bucket, "milk", 3)
    assert Bucket.delete(bucket, "milk") == 3
    dbg(Bucket.delete(bucket, "milk"))
  end
end
