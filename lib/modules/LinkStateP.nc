#include "../../includes/packet.h"
#include "../../includes/RoutingTable.h"
#include "../../includes/NeighborTable.h"

module LinkStateP{
provides interface LinkState;

// provides interface SimpleSend as Flooder;

uses interface Receive as Receiver;
uses interface Hashmap<LSA> as Cache;
uses interface NeighborDiscovery as Neighbor;
uses interface Flooding as Flooder;

}
implementation{


 

   uint8_t  receivedCount = 0;
    uint8_t  expectedCount = MAX_NODES;
    uint16_t sequenceNum = 1;
    neighbor_t lsTable[MAX_NEIGHBORS];
    //Maybe have a start function that fills
    LSA lsa;
    uint16_t payloadSize;

    void createRouting();
    uint16_t firstLSA(LSA* inlsa);

   //check to see if NeighborDiscovery is Done 
    event void Neighbor.done(){ 
        dbg("routing","NeigborDiscovery Complete");
        // When Neighbor Discovery is done, I want to begin flooding LSA's
        call Neighbor.getNeighbor(lsTable);
        // call LinkState.floodLSA();
    
    }

    command void LinkState.floodLSA(){
        dbg("routing", "Flooding LSA");
         payloadSize = firstLSA(&lsa);

         call Flooder.LSAsend(lsa, payloadSize);


    }




    event message_t* Receiver.receive(message_t* msg, void* payload, uint8_t len){
        LSA* recLSA = (LSA*)payload;
        uint16_t tempPayloadSize;
        //check to see if its in the Cache

        if (call Cache.contains(recLSA->src)){

            LSA currLSA = call Cache.get(recLSA->src);
            if (recLSA->seq <= currLSA.seq){
                return msg;
            }
        }

        call Cache.insert(recLSA->src, *recLSA);


        receivedCount++;

        tempPayloadSize = firstLSA(recLSA);

        if (call Flooder.LSAsend(*recLSA, tempPayloadSize) != SUCCESS){
            dbg("routing", "Failed to flood\n");
        }
        else{
            dbg("routing","Flooding LSA from node %d w/ seq %d\n", recLSA->src, recLSA->seq);
        }

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
     uint16_t firstLSA(LSA* inlsa ){
        uint8_t i;
        uint8_t tupleIndex = 0;
        tuple_t tempTuple;
        uint16_t fieldSize;
        uint16_t tupleSize;
        uint16_t paylodSize;
        

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

         fieldSize = sizeof(uint16_t) + sizeof(uint16_t);
         tupleSize = tupleIndex * sizeof(tuple_t);
         paylodSize = fieldSize + tupleSize;
        
        return payloadSize;


     }
    //  void lsaSize(LSA sizeLSA){
    //     uint8_t fieldSize = sizeof(sizeLSA->src) + sizeof(sizeLSA->seq);
    //     uint8_t tupleSize = tupleIndex * sizeof(tuple_t);
    //     uint8_t paylodSize = fieldSize + tupleSize;

    //  }



}