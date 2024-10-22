#include "../../includes/am_types.h"

configuration IPmodC{
    provides interface IPmod;
}
implementation{
    components IPmodP;
    components new AMSenderC(AM_PACK);
    components new AMReceiverC(AM_PACK);
    components LinkStateC;
    // components ActiveMessageC;

    IPmod = IPmodP.IP;
    IPmodP.Sender -> AMSenderC;
    IPmodP.Receiver -> AMReceiverC;
    IPmodP.Packet -> AMSenderC;
    IPmodP.AMPacket -> AMSenderC;
    IPmodP.LinkState -> LinkStateC;
}