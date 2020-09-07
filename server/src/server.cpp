#include <chrono>
#include <iostream>
#include <string>
#include <thread>
#include <zmq.hpp>

#include "spdlog/spdlog.h"

void s_send(zmq::socket_t& socket, const std::string& message) {
  std::cout << "push message: " << message << "\n";
  socket.send(zmq::message_t(message.data(), message.size()),
              zmq::send_flags::dontwait);
}

std::string s_recv(zmq::socket_t& socket) {
  zmq::message_t msg;
  if (socket.recv(msg, zmq::recv_flags::none)) {
    return msg.data<char>();
  } else {
    return "";
  }
}

//  Provide random number from 0..(num-1)
#define within(num) (int)((float)((num)*random()) / (RAND_MAX + 1.0))

int main() {
  srandom((unsigned)time(NULL));

  spdlog::info("start server...");

  zmq::context_t context(1);
  zmq::socket_t server(context, ZMQ_REP);
  server.bind("tcp://*:5555");

  int cycles = 0;
  while (1) {
    std::string request = s_recv(server);
    cycles++;

    // Simulate various problems, after a few cycles
    // if (cycles > 3 && within(3) == 0) {
    //   std::cout << "I: simulating a crash" << std::endl;
    //   break;
    // } else if (cycles > 3 && within(3) == 0) {
    //   std::cout << "I: simulating CPU overload" << std::endl;
    //   std::this_thread::sleep_for(std::chrono::milliseconds(2));
    // }
    std::cout << "I: normal request (" << request << ")" << std::endl;
    // std::this_thread::sleep_for(
    //     std::chrono::milliseconds(1));  // Do some heavy work
    s_send(server, request);
  }
  return 0;
}