#include <boost/process.hpp>
#include <iostream>
#include <string>
#include <thread>

int main() {
  std::cout << "Start demo!\n";

  boost::process::child producer("./producer");
  boost::process::child consumer("./consumer");

  consumer.wait();
  producer.wait();

  return 0;
}