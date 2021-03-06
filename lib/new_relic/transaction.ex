defmodule NewRelic.Transaction do
  @moduledoc """
  Records information about an instrumented web transaction.
  """

  defstruct [:name, :start_time]

  @typedoc "A New Relixir transaction context."
  @opaque t :: %__MODULE__{name: String.t, start_time: :erlang.timestamp}

  @typedoc "The name of a model."
  @type model :: String.t

  @typedoc "The name of a repository action."
  @type action :: atom

  @typedoc "The name of a query."
  @type query :: String.t | {model, action}

  @typedoc "Elapsed time in microseconds."
  @type interval :: non_neg_integer

  @doc """
  Creates a new web transaction.

  This method should be called just before processing a web transaction.
  """
  @spec start(String.t) :: t
  def start(name) when is_binary(name) do
    %__MODULE__{name: name, start_time: :os.timestamp}
  end

  @doc """
  Updates the name of an existing transaction

  This method allows you to specify the name of a transaction after start to
  facilitate the use case where the transaction name is not known at start time.
  """
  @spec update_name(t, String.t) :: t
  def update_name(transaction, new_name) do
    %{transaction | name: new_name}
  end

  @doc """
  Finishes a web transaction.

  This method should be called just after processing a web transaction. It will record the elapsed
  time of the transaction.
  """
  @spec finish(t) :: :ok
  def finish(%__MODULE__{start_time: start_time} = transaction) do
    end_time = :os.timestamp
    elapsed = :timer.now_diff(end_time, start_time)

    record_value!(transaction, :total, elapsed)
  end

  @doc """
  Records a database query for the current web transaction.

  The query name can either be provided as a raw string or as a tuple containing a model and action
  name.
  """
  @spec record_db(t, query, interval) :: :ok
  def record_db(%__MODULE__{} = transaction, {model, action}, elapsed) do
    record_db(transaction, "#{model}.#{action}", elapsed)
  end

  def record_db(%__MODULE__{} = transaction, query, elapsed) when is_binary(query) do
    record_value!(transaction, {:db, query}, elapsed)
  end

  defp record_value!(%__MODULE__{name: name}, data, elapsed) do
    NewRelic.Collector.record_value({name, data}, elapsed)
  end
end
