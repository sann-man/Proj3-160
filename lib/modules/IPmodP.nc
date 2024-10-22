#include "../../includes/RoutingTable.h"
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"

module IPmodP{
    provides interface IPmod as IP;
    uses interface Receive as Receiver;
    uses interface AMSend as Sender;
    uses interface Packet;
    uses interface AMPacket;

    uses interface LinkState;

}
implementation{
    message_t pkt;
    bool busy = FALSE;

    routing_t routingTable[MAX_NODES];

     void forwardPacket(pack* msg);

    command void IP.start(){
        dbg("routing","IPmod module started");
        call LinkState.getTable(routingTable);
    }

    command error_t IP.send(pack* msg, uint16_t dest){
            uint16_t nextHop;
            error_t result;
        if (!busy){
            pack* payload = (pack*)(call Packet.getPayload(&pkt, sizeof(pack)));
            if(payload == NULL){
                return FAIL;
            }

            memcpy(payload, msg, sizeof(pack));
            payload->src = TOS_NODE_ID;
            payload->dest = dest;
            payload->TTL = msg->TTL;

             nextHop = routingTable[dest].nexthop;
             result = call Sender.send(nextHop, &pkt, sizeof(pack));

            if (result == SUCCESS){
                busy = TRUE;
                return SUCCESS;
            }
            else{
                return FAIL;
            }
        } else{
            return EBUSY;
        }
    }

    event void IP.packetReceived(pack msg){
        return;

    }

    event message_t* Receiver.receive(message_t* msg, void* payload, uint8_t len){
        pack* receivedPack = (pack*)payload;

        if (receivedPack->TTL == 0){
            return msg;
        }

        if (receivedPack->dest == TOS_NODE_ID){
             signal IP.packetReceived(*receivedPack);
        }
        else{
            receivedPack->TTL--;
            forwardPacket(receivedPack);
        }

        return msg;
    }

    event void Sender.sendDone(message_t* msg, error_t result){
        if(&pkt == msg){
            busy = FALSE;

        }
    }

    void forwardPacket(pack* msg){
        error_t result;
        uint16_t nextHop;

         nextHop = routingTable[msg->dest].nexthop;

        if (nextHop == MAX_NUMBER){
            return;
        }
        
         result = call IP.send(msg, msg->dest);
        if (result == SUCCESS){
            dbg("routing", "Forwarding Packet to next hop %d\n", nextHop);
        } else{
            dbg("routing", "Forwarding has failed to send to %d\n", nextHop);
        }
    }



}