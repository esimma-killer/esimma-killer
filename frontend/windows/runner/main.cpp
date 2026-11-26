#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter_windows.h>
#include <windows.h>

#include <algorithm>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  RECT work_area{};
  ::SystemParametersInfo(SPI_GETWORKAREA, 0, &work_area, 0);
  const HMONITOR monitor =
      MonitorFromPoint(POINT{0, 0}, MONITOR_DEFAULTTOPRIMARY);
  const UINT dpi = monitor != nullptr
      ? FlutterDesktopGetDpiForMonitor(monitor)
      : GetDpiForSystem();
  const double scale = dpi / 96.0;
  const int logical_work_w =
      static_cast<int>((work_area.right - work_area.left) / scale);
  const int logical_work_h =
      static_cast<int>((work_area.bottom - work_area.top) / scale);
  int window_w = std::min(1280, std::max(720, logical_work_w - 80));
  int window_h = std::min(800, std::max(540, logical_work_h - 80));
  window_w = std::min(window_w, logical_work_w);
  window_h = std::min(window_h, logical_work_h);
  const Win32Window::Point origin(
      static_cast<unsigned int>(std::max(0, (logical_work_w - window_w) / 2)),
      static_cast<unsigned int>(std::max(0, (logical_work_h - window_h) / 2)));
  const Win32Window::Size size(
      static_cast<unsigned int>(window_w),
      static_cast<unsigned int>(window_h));
  if (!window.Create(L"UAA | Alumno - Inicio", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
