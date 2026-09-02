#include "task_runner_linux.h"

#include <glib.h>

namespace livekit_client_plugin {

void TaskRunnerLinux::EnqueueTask(TaskClosure task) {
  {
    std::lock_guard<std::mutex> lock(tasks_mutex_);
    tasks_.push(std::move(task));
  }

  GMainContext* context = g_main_context_default();
  if (context) {
    // A weak_ptr (not `this`) is passed through so that if the runner is
    // destroyed before the main loop dispatches this callback, for example
    // when the owning sink is torn down while an audio frame's task is still
    // queued, the callback safely no-ops instead of locking a mutex inside
    // freed memory. g_main_context_invoke_full's notify always runs exactly
    // once, whether the callback fired inline or via the idle source, so the
    // heap-allocated weak_ptr is never leaked.
    //
    // weak_from_this() itself is only safe here because the owning sink is
    // destroyed after the audio track's RemoveSink() returns, and RemoveSink()
    // blocks until any in-flight OnData() (and therefore this call) has
    // finished. Callers must keep that ordering.
    auto* weak_self = new std::weak_ptr<TaskRunnerLinux>(weak_from_this());
    g_main_context_invoke_full(
        context, G_PRIORITY_DEFAULT,
        [](gpointer user_data) -> gboolean {
          auto* weak_self = static_cast<std::weak_ptr<TaskRunnerLinux>*>(user_data);
          if (auto runner = weak_self->lock()) {
            // Take the whole batch under the lock, then run it unlocked so a
            // task that re-enters EnqueueTask on this runner cannot deadlock
            // on the non-recursive mutex.
            std::queue<TaskClosure> pending;
            {
              std::lock_guard<std::mutex> lock(runner->tasks_mutex_);
              std::swap(pending, runner->tasks_);
            }
            while (!pending.empty()) {
              TaskClosure task = std::move(pending.front());
              pending.pop();
              task();
            }
          }
          return G_SOURCE_REMOVE;
        },
        weak_self,
        [](gpointer user_data) {
          delete static_cast<std::weak_ptr<TaskRunnerLinux>*>(user_data);
        });
  }
}

}  // namespace livekit_client_plugin
