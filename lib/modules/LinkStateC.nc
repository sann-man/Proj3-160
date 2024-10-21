#include "../../includes/packet.h"

configuration LinkStateC{
provides interface LinkState;
uses interface Hashmap<LSA> as Hashmap;
}

implementation{
components LinkStateP;

LinkState = LinkStateP.LinkState;

// components new HashmapC(LSA, 20) as Hashmap;

LinkStateP.Cache = Hashmap;

components NeighborDiscoveryC as Neighbor;
LinkStateP.Neighbor -> Neighbor;

// components FloodingP as Flooder;
// LinkStateP.Flooder -> Flooder;

components new AMReceiverC(AM_PACK) as Receiver;
LinkStateP.Receiver -> Receiver;



}