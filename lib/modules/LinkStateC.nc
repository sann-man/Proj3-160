#include "../../includes/packet.h"

configuration LinkStateC{
provides interface LinkeState;
}

implementation{
components LinkStateP;

LinkState = LinkStateP.LinkState;

components new HashmapC(uint16_t, 20);

HashmapP.Hashmap -> HashmapC;

components NeighborDiscoveryP as Neighbor;
NeighborDiscoveryP.Neighbor -> Neighbor;

components FloodingP as Flooder;
FloodingP.Flooder -> Flooder;



}