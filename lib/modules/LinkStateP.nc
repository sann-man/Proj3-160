#include "../../includes/packet.h"
#include "../../includes/RoutingTable.h"
#include "../../includes/NeighborTable.h"

module LinkStateP{
provides interface LinkState;

// provides interface SimpleSend as Flooder;

uses interface Receive as Receiver;
uses interface Hashmap<LSA> as Cache;
uses interface NeighborDiscovery as Neighbor;
// uses interface Flooding as Flooder;

}
implementation{


 

   uint8_t  receivedCount = 0;
    uint8_t  expectedCount = MAX_NODES;
    uint16_t sequenceNum = 1;
    neighbor_t lsTable[MAX_NEIGHBORS];
    //Maybe have a start function that fills
    LSA lsa;

    void createRouting();
    void firstLSA(LSA* inlsa);
    
    event void Neighbor.done(){ 
        dbg("routing","NeigborDiscovery Complete");
        // When Neighbor Discovery is done, I want to begin flooding LSA's
        call Neighbor.getNeighbor(lsTable);
        // floodLSA();
    
    }

    command void LinkState.floodLSA(){
        dbg("routing", "Flooding LSA");
        firstLSA(&lsa);

        // call Flooder.send(lsa, AM_BROADCAST_ADDR);


    }




    event message_t* Receiver.receive(message_t* msg, void* payload, uint8_t len){
        LSA* recLSA = (LSA*)payload;
        //check to see if its in the Cache

        if (call Cache.contains(recLSA->src)){

            LSA currLSA = call Cache.get(recLSA->src);
            if (recLSA->seq <= currLSA.seq){
                return msg;
            }
        }

        call Cache.insert(recLSA->src, *recLSA);

        if (receivedCount >= expectedCount){
             createRouting();
            return;
        }


        //if msg->seq == Cache.get(msg->src)->seq or less than, return msg as it is, since there is nothing we can do
        //if ms->seq > Cache.get(msg->src)->seq, then we update cache with that lsa
        //we then check to see if we have received all nodes
        //if receivedCount == expectedCount, then we start with the routing table

    }

    

     void createRouting(){
        return;

     }
     void buildGraph(){
        return;
        
     }
     void firstLSA(LSA* inlsa ){
        uint8_t i;
        uint8_t tupleIndex = 0;
        tuple_t tempTuple;
        

        inlsa->src = TOS_NODE_ID;
        inlsa->seq = sequenceNum;
        for (i = 0; i < MAX_NEIGHBORS; i++ ){
            if (lsTable[i].neighborID == inlsa->src && tupleIndex < MAX_TUPLE){
                tempTuple.neighbor = lsTable[i].neighborID;
                tempTuple.cost = lsTable[i].linkQuality;
                inlsa->tupleList[tupleIndex] = tempTuple;
                tupleIndex++;
            }
        }
        


     }



}