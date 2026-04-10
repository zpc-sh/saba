defmodule Saba.Hall.Policy do
  @moduledoc """
  Executable policy helpers for Conversational Computing v2 in Saba.

  This keeps core governance rules available as code so services and resources
  can enforce the same contract defined in the specification docs.
  """

  @move_types [
    :assert,
    :challenge,
    :clarify,
    :concede,
    :reframe,
    :fork,
    :fold,
    :unfold,
    :collapse,
    :crystallize,
    :prune,
    :archive,
    :rehydrate
  ]

  @core_invariants [
    :identity,
    :lineage,
    :challengeability,
    :commitment,
    :fold_unfold,
    :archive_restart
  ]

  @archive_policy %{
    max_branches: 800,
    max_entropy: 12.0,
    max_pressure: 10.0,
    max_traversal_cost: 5_000,
    max_fold_density: 0.65,
    max_latency_ms: 1_500
  }

  @capital_day %{
    frequency: :monthly,
    day_of_month: 1,
    example_prompt: "AI-vs-AI Coca-Cola vs Pepsi"
  }

  @pierce_payload_keys [
    :commitment_set,
    :lineage_path,
    :replay_l0_l2,
    :policy_and_adapter_versions
  ]

  def move_types, do: @move_types

  def core_invariants, do: @core_invariants

  def archive_policy, do: @archive_policy

  def capital_day, do: @capital_day

  def pierce_payload_minimum, do: @pierce_payload_keys

  def valid_move_type?(type) when is_atom(type), do: type in @move_types
  def valid_move_type?(type) when is_binary(type), do: type in Enum.map(@move_types, &Atom.to_string/1)
  def valid_move_type?(_), do: false

  def capital_day?(%Date{} = date), do: date.day == @capital_day.day_of_month
  def capital_day?(%DateTime{} = datetime), do: datetime |> DateTime.to_date() |> capital_day?()
  def capital_day?(%NaiveDateTime{} = datetime), do: datetime |> NaiveDateTime.to_date() |> capital_day?()
  def capital_day?(_), do: false

  def authoritative_cross_branch_claim?(payload) when is_map(payload) do
    truthy?(map_get(payload, :authoritative)) and
      map_get(payload, :target_scope) in ["cross_branch", :cross_branch]
  end

  def authoritative_cross_branch_claim?(_), do: false

  def authoritative_claim_allowed?(payload) do
    not authoritative_cross_branch_claim?(payload) or pierce_payload_complete?(payload)
  end

  def pierce_payload_complete?(payload) when is_map(payload) do
    non_empty_list?(map_get(payload, :commitment_set)) and
      non_empty_list?(map_get(payload, :lineage_path)) and
      replay_payload_complete?(map_get(payload, :replay)) and
      non_empty_binary?(map_get(payload, :policy_version)) and
      non_empty_list?(map_get(payload, :adapter_versions))
  end

  def pierce_payload_complete?(_), do: false

  defp replay_payload_complete?(replay) when is_map(replay) do
    non_empty_binary?(map_get(replay, :L0)) and
      non_empty_binary?(map_get(replay, :L1)) and
      non_empty_binary?(map_get(replay, :L2))
  end

  defp replay_payload_complete?(_), do: false

  defp non_empty_binary?(value), do: is_binary(value) and String.trim(value) != ""
  defp non_empty_list?(value), do: is_list(value) and value != []

  defp truthy?(value), do: value in [true, "true", :true, 1]

  defp map_get(map, key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
