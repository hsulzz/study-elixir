defmodule ServerProcess do
  def call(server_pid, request) do
    send(server_pid,{:call, request, self()})
  end

  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
  end

  defp loop(callback_module, current_state) do
    receive do
      {:call, resquest, caller} ->
        {response,new_state} = callback_module.handle_call(
          request,
          current_state
        )
        send(caller, {:response, response})
        loop(callback_module,new_state)

      {:cast, reuqest} ->
        new_state = callback_module.handle_cast(
          request,
          current_state
        )
        loop(callback_module,new_state)
    end
  end
end
