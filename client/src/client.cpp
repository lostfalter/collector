#include <chrono>
#include <iostream>
#include <memory>
#include <string>
#include <thread>

#include "nlohmann/json.hpp"
#include "spdlog/spdlog.h"
#include "zmq.hpp"

#define REQUEST_TIMEOUT 2500  //  msecs, (> 1000!)
#define REQUEST_RETRIES 3     //  Before we abandon

//  Helper function that returns a new configured socket
//  connected to the Hello World server
//
std::unique_ptr<zmq::socket_t> make_client_socket(zmq::context_t& context) {
  std::cout << "I: connecting to server…" << std::endl;
  std::unique_ptr<zmq::socket_t> client(new zmq::socket_t(context, ZMQ_REQ));
  client->connect("tcp://localhost:5555");

  //  Configure socket to not wait at close time
  int linger = 0;
  client->setsockopt(ZMQ_LINGER, &linger, sizeof(linger));
  return client;
}

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

int main() {
  spdlog::info("start client...");

  nlohmann::json j2 = {{"pi", 3.141},
                       {"happy", true},
                       {"name", "Niels"},
                       {"nothing", nullptr},
                       {"answer", {{"everything", 42}}},
                       {"list", {1, 0, 2}},
                       {"object", {{"currency", "USD"}, {"value", 42.99}}}};

  spdlog::info(j2.dump(4));

  zmq::context_t context(1);

  auto client = make_client_socket(context);

  int sequence = 0;
  int retries_left = REQUEST_RETRIES;

  while (retries_left) {
    std::stringstream request;
    request << ++sequence << " request from client";
    s_send(*client, request.str());
    // std::this_thread::sleep_for(std::chrono::milliseconds(1));

    bool expect_reply = true;
    while (expect_reply) {
      //  Poll socket for a reply, with timeout
      zmq::pollitem_t items[] = {
          {static_cast<void*>(*client), 0, ZMQ_POLLIN, 0}};
      zmq::poll(&items[0], 1, REQUEST_TIMEOUT);

      //  If we got a reply, process it
      if (items[0].revents & ZMQ_POLLIN) {
        //  We got a reply from the server, must match sequence
        std::string reply = s_recv(*client);
        if (atoi(reply.c_str()) == sequence) {
          std::cout << "I: server replied OK (" << reply << ")" << std::endl;
          retries_left = REQUEST_RETRIES;
          expect_reply = false;
        } else {
          std::cout << "E: malformed reply from server: " << reply << std::endl;
        }
      } else if (--retries_left == 0) {
        std::cout << "E: server seems to be offline, abandoning" << std::endl;
        expect_reply = false;
        break;
      } else {
        std::cout << "W: no response from server, retrying…" << std::endl;
        //  Old socket will be confused; close it and open a new one
        client = make_client_socket(context);
        //  Send request again, on new socket
        s_send(*client, request.str());
      }
    }
  }

  return 0;
}