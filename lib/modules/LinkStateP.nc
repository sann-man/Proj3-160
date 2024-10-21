#include "../../includes/packet.h"
#include "../../includes/RoutingTable.h"
#include "../../includes/NeighborTable.h"

module LinkStateP{
provides interface LinkState;
use interface Receive as Receiver;
use interface Hashmap<uint16_t> as Cache;
use interface NeighborDiscovery as Neighbor;
use interface Flooding as Flooder;

}
implementation{

 

   uint8_t  receivedCount = 0;
    uint8_t  expectedCount = MAX_NODES;
    uint16_t sequenceNum = 1;
    neighbor_t lsTable[MAX_NEIGHBORS];
    //Maybe have a start function that fills

    
    event void NeighborDiscovery.done(){ 
        dbg("routing","NeigborDiscovery Complete")
        // When Neighbor Discovery is done, I want to begin flooding LSA's
        call Neighbor.getNeighbor(lsTable);
        floodLSA();
    
    }

    void floodLSA(){
        dbg("routing", "Flooding LSA")
        LSA lsa;
        initLSA(&lsa);

        Flooder.send(lsa, AM_BROADCAST_ADDR);


    }




    event meesage_t* Receiver.receive(message_t* msg){
        LSA* lsa = (LSA*)msg;
        //check to see if its in the Cache

        if (Cache.contains(lsa->src)){

            LSA* currLSA = Cache.get(lsa->src);
            if (lsa->seq <= currLSA->seq){
                return msg;
            }
        }

        Cache.insert(lsa->src, *lsa);
        
        if (receivedCount >= expectedCount){
            createRouting();
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
     void initLSA(LSA* lsa ){
        uint8_t i;
        uint8_t tupleIndex = 0;
        tuple_t tempTuple;
        

        lsa.src = TOS_NODE_ID;
        lsa.seq = sequenceNum;
        for (i = 0; i < MAX_NEIGHBORS; i++ ){
            if (neighborTable[i].ID == lsa->src && tupleIndex < MAX_TUPLE){
                tempTuple.neighbor = neighborTable[i].neighborID;
                tempTuple.cost = neighborTable[i].linkQuality;
                lsa.tupleList[tupleIndex] = tempTuple;
                tupleIndex++;
            }
        }
        


     }



}