#include "../../includes/RoutingTable.h"
interface LinkState {
    // command error_t start();
    // event void NeighborDiscovery.done();
    command void floodLSA();
    command void getTable(routing_t* tableRoute);
}