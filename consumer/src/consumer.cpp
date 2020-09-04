#include <chrono>
#include <iostream>
#include <string>
#include <thread>
#include <zmq.hpp>

int main() {
  std::cout << "Hi, here is a consumer!\n";

  zmq::context_t ctx;
  zmq::socket_t sock(ctx, zmq::socket_type::pull);
  sock.bind("ipc://log_collector_consumer");

  while (true) {
    zmq::message_t msg;
    auto ret = sock.recv(msg, zmq::recv_flags::none);
    if (ret) {
      std::cout << "Got message: " << msg << "\n";
    } else {
      return 1;
    }
  }

  return 0;
}