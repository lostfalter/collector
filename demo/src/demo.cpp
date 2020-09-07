#include <boost/process.hpp>
#include <iostream>
#include <string>
#include <thread>

void tesProducerAndConsumer() {
  boost::process::child producer("./producer");
  boost::process::child consumer("./consumer");

  consumer.wait();
  producer.wait();
}

void tesServerAndClient() {
  boost::process::child server("./server");
  boost::process::child client("./client");

  client.wait();
  server.wait();
}

int main() {
  std::cout << "Start demo!\n";

  tesServerAndClient();

  return 0;
}