defmodule PolicrMiniBot.AdminPermissionsChangePreheater do
  @moduledoc """
  同步管理员权限修改的插件。
  """

  use PolicrMiniBot, plug: :preheater

  alias PolicrMini.Logger

  @doc """
  根据更新消息中的 `chat_member` 字段，同步管理员权限变化。

  ## 以下情况将不进入流程（按顺序匹配）：
  - 更新不包含 `chat_member` 数据。
  - 更新来自频道。
  - 状态中的 `action` 字段为 `:user_joined` 或 `:user_lefted`。备注：用户加入和管理员权限无关，用户离开有独立的模块处理权限。
  - 成员现在的状态是 `member` 或 `restricted`，并且之前的状态也是 `memeber`、`restricted`。备注：权限变化和管理员权限无关。
  - 成员现在的状态是 `left` 并且之前的状态是 `kicked`。备注：从封禁列表中解封用户和管理员权限无关。
  """

  # !注意! 由于依赖状态中的 `action` 字段，此模块需要位于管道中的涉及填充状态相关字段、相关值的插件后面。
  # 当前此模块需要保证位于 `PolicrMiniBot.InitUserJoinedActionPreheater` 和 `PolicrMiniBot.UserLeftedPreheater` 两个模块的后面。
  @impl true
  def call(%{chat_member: nil} = _update, state) do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: %{chat: %{type: "channel"}}}, state) do
    {:ignored, state}
  end

  @impl true
  def call(_update, %{action: action} = state) when action in [:user_joined, :user_lefted] do
    {:ignored, state}
  end

  @impl true
  def call(
        %{
          chat_member: %{
            new_chat_member: %{status: status_new},
            old_chat_member: %{status: status_old}
          }
        },
        state
      )
      when status_new in ["member", "restricted"] and status_old in ["member", "restricted"] do
    {:ignored, state}
  end

  @impl true
  def call(
        %{
          chat_member: %{
            new_chat_member: %{status: status_new},
            old_chat_member: %{status: status_old}
          }
        },
        state
      )
      when status_new == "lefted" and status_old == "kicked" do
    {:ignored, state}
  end

  # 有 bug 待处理：未接管导致状态字段没有填充。
  @impl true
  def call(%{chat_member: chat_member}, state) do
    %{chat: %{id: chat_id}, new_chat_member: %{user: %{id: user_id}}} = chat_member

    Logger.debug(
      "The permissions of an administrator have changed. #{inspect(chat_id: chat_id, user_id: user_id)}"
    )

    # IO.inspect(chat_member)

    {:ok, state}
  end
end
