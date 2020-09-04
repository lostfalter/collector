#include <chrono>
#include <iostream>
#include <string>
#include <thread>
#include <zmq.hpp>

int main() {
  std::cout << "Hi, here is a producer!\n";

  zmq::context_t ctx;
  zmq::socket_t sock(ctx, zmq::socket_type::push);
  sock.connect("ipc://log_collector_consumer");

  int i = 1;
  while (true) {
    std::string content = "Hello, world, " + std::to_string(i++);
    std::cout << "push message: " << content << "\n";
    sock.send(zmq::message_t(content.data(), content.size()),
              zmq::send_flags::dontwait);

    std::this_thread::sleep_for(std::chrono::seconds(1));
  }

  return 0;
}