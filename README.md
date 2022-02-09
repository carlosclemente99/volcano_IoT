# volcano_IoT
This project is composed of two files:
- Gateway.pde: code of the gateway node. Receives messages from XBee, parses the message and publishes it to ThingSpeak. In addition, it prints gateway's built in sensor values and publishes them to ThingSpeak.
- EndNode.pde: code of the end node. Collects its own sensor's values and sends them through XBee.
