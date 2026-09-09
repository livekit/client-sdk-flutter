#ifndef PACKAGES_FLUTTER_WEBRTC_LINUX_TASK_RUNNER_LINUX_H_
#define PACKAGES_FLUTTER_WEBRTC_LINUX_TASK_RUNNER_LINUX_H_

#include <memory>
#include <mutex>
#include <queue>
#include <functional>

using TaskClosure = std::function<void()>;

namespace livekit_client_plugin {

// Owned via std::shared_ptr by its creator (never std::unique_ptr). EnqueueTask
// schedules a GLib idle callback that runs asynchronously on the main loop, and
// enable_shared_from_this lets that callback hold a weak reference so it can
// detect the runner having been destroyed in the meantime (for example
// stopAudioRenderer tearing down the sink while a callback is still queued)
// instead of dereferencing freed memory.
class TaskRunnerLinux : public std::enable_shared_from_this<TaskRunnerLinux> {
 public:
  TaskRunnerLinux() = default;
  ~TaskRunnerLinux() = default;

  // TaskRunner implementation.
  void EnqueueTask(TaskClosure task);

 private:
  std::mutex tasks_mutex_;
  std::queue<TaskClosure> tasks_;
};

}  // namespace livekit_client_plugin

#endif  // PACKAGES_FLUTTER_WEBRTC_LINUX_TASK_RUNNER_LINUX_H_