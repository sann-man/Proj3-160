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
    uint8_t  expectedCount = 4;
    uint16_t sequenceNum = 1;
    neighbor_t lsTable[MAX_NEIGHBORS];

    uint8_t sendAttempts = 0;
    //Maybe have a start function that fills
    LSA lsa;
    uint16_t payloadSize;
    routing_t routingTable[MAX_NODES];

    //Routing Table variables
    uint16_t graph[MAX_NODES][MAX_NODES];

    void createRouting();
    uint16_t firstLSA(LSA* inlsa);
     void dijsktraAlgo(uint16_t startNode);
     void buildGraph();

   //check to see if NeighborDiscovery is Done 
    event void Neighbor.done(){ 
        dbg("routing","NeigborDiscovery Complete");
        // When Neighbor Discovery is done, I want to begin flooding LSA's
        call Neighbor.getNeighbor(lsTable);
        call LinkState.floodLSA();
    
    }

    command void LinkState.floodLSA(){
        dbg("routing", "Flooding LSA");

         payloadSize = firstLSA(&lsa);

         call Flooder.LSAsend(lsa, payloadSize);


    }

    bool cacheisFull(){
        uint8_t i;
        for(i =1; i < MAX_NODES;i++){
            if (!call Cache.contains(i)){
                dbg("routing", "Cache not full\n");
                return FALSE;
            }
        }
        dbg("routing","Cache filled\n");
        return TRUE;
    }

    // void resendLSA(LSA* reLSA, uint8_t repaylodSize){
    //     sendAttempts++;
    //     if (sendAttempts > 4){
    //         dbg("routing", "Failed to Flood Entirely");
    //     }
    //      if (call Flooder.LSAsend(*reLSA, repaylodSize) != SUCCESS){
    //         dbg("routing", "Resending LSA");
    //         resendLSA(reLSA, repaylodSize);
    //      }
    //      else{
    //         dbg("routing","Flooding LSA from node %d w/ seq %d\n", reLSA->src, reLSA->seq);

    //      }

    // }




    event message_t* Receiver.receive(message_t* msg, void* payload, uint8_t len){
        LSA* recLSA = (LSA*)payload;
        uint16_t tempPayloadSize;
        
        //check to see if its in the Cache
        // LSA currLSA = call Cache.get(recLSA->src);

        if (call Cache.contains(recLSA->src)){

            LSA currLSA = call Cache.get(recLSA->src);
            if (recLSA->seq <= currLSA.seq){
                return msg;
            }
        }

        call Cache.insert(recLSA->src, *recLSA);
        // if (!call  Cache.contains(recLSA->src)){
        //     call Cache.insert(recLSA->src, *recLSA);
        //     dbg("routing", "Inserted LSA from node %d into cache with seq %d\n", recLSA->src, recLSA->seq);
        // } else {
        //     LSA currLSA = call Cache.get(recLSA->src);
        //     if ( recLSA->seq > currLSA.seq){
        //     call Cache.insert(recLSA->src, *recLSA);
        //     dbg("routing", "Updated LSA from node %d into cache with seq %d\n", recLSA->src, recLSA->seq);
        //      } else{
        //           dbg("routing", "Ignore old/duplicate LSA from node %d with seq %d\n", recLSA->src, recLSA->seq);
        //      }
        // }

        
        receivedCount++;
        dbg("routing", "CURRENT RECEIVE COUNT: %d\n", receivedCount);

        tempPayloadSize = firstLSA(recLSA);

        if (call Flooder.LSAsend(*recLSA, tempPayloadSize) != SUCCESS){
            dbg("routing", "Failed to flood\n");
            // resendLSA(recLSA, tempPayloadSize);
        }
        else{
            dbg("routing","Flooding LSA from node %d w/ seq %d\n", recLSA->src, recLSA->seq);
        }

        // if (cacheisFull()){
        //     dbg("routing", "Begin creating Routing Table");
        //      createRouting();
        //     // return msg;
        // }
        if (receivedCount == expectedCount){
            dbg("routing", "Begin creating Routing Table\n");
             createRouting();
            // return msg;
        }

        return msg;


        //if msg->seq == Cache.get(msg->src)->seq or less than, return msg as it is, since there is nothing we can do
        //if ms->seq > Cache.get(msg->src)->seq, then we update cache with that lsa
        //we then check to see if we have received all nodes
        //if receivedCount == expectedCount, then we start with the routing table

    }

    

     void createRouting(){
        dbg("routing","Begin to build Graph\n");
        buildGraph();

        dbg("routing", "Begin to do Dijktra's\n");
        dijsktraAlgo(TOS_NODE_ID);
        return;

     }
     void buildGraph(){ //Build Adjacency Matrix
        uint8_t i;
        uint8_t j;
        uint8_t nodeIndex;
        LSA cacheLSA;

        uint16_t neighbor;
        uint16_t cost;

        for (i =0; i < MAX_NODES; i++){
            for (j =0; j < MAX_NODES;j++){
                graph[i][j] = MAX_NUMBER; //All Start with max number (infinity)
            }
        }

        for (nodeIndex = 0; nodeIndex < MAX_NODES; nodeIndex++){
            if (call Cache.contains(nodeIndex)){
                 cacheLSA = call Cache.get(nodeIndex);

                 for (i = 0; i < MAX_TUPLE && cacheLSA.tupleList[i].neighbor != 0; i++){
                    // check to see the neighbor and cost it has 
                    neighbor = cacheLSA.tupleList[i].neighbor; //get the tuple's neighbor
                     cost = cacheLSA.tupleList[i].cost; //get the tuple's cost

                    graph[cacheLSA.src][neighbor] = cost; // where the node and neighbor is, put the cost. 
                 }
            }
        }

        dbg("routing", "Adjacency Matrix from Cache\n");
        for (i = 0; i < MAX_NODES; i++){
            for (j = 0; j < MAX_NODES; j++){
                if(graph[i][j] != MAX_NUMBER){
                    dbg("routing", "graph[%d][%d] = %d\n", i, j, graph[i][j]);
                }
            }
        }

        
        
        
     }

     void dijsktraAlgo(uint16_t startNode){
        uint8_t visited[MAX_NODES]; //have we vistited the "node"
        uint8_t distance[MAX_NODES]; // tracks the shortest distance 
        uint16_t i,j, minDistance, nextNode, altCost;

        for (i = 0; i < MAX_NODES; i++){
            distance[i] = graph[startNode][i]; //distance from start node to i
            visited[i] = 0; //going to be 

            routingTable[i].dest = i;
            routingTable[i].nexthop = (graph[startNode][i] != MAX_NUMBER) ? i : startNode;
            routingTable[i].cost = distance[i]; //
            routingTable[i].BUhop = MAX_NUMBER; //Start with max
            routingTable[i].BUcost = MAX_NUMBER; //start with max 

            dbg("routing", "Table Check: destination: %d, nextHop: %d\n",routingTable[i].dest, routingTable[i].nexthop);

        }

        distance[startNode] = 0; // From itself to itself is 0
        visited[startNode] = 1; //we have visited

        for (i = 1; i < MAX_NODES; i++){
            minDistance = MAX_NUMBER; //minimy distance will be INFINITY
            nextNode = startNode;

            for (j = 0; j < MAX_NODES; j++){
                if (!visited[j] && distance[j] < minDistance){ //If we haven't visited it and distance is < minimum 
                    minDistance = distance[j];
                    nextNode = j;
                }
            }

            visited[nextNode] = 1; // we have visited next node

            for (j = 0; j < MAX_NODES; j++){
                if (!visited[j] && graph[nextNode][j] != MAX_NUMBER){ //If we haven't visited
                    altCost = minDistance + graph[nextNode][j];
                

                if (altCost < distance[j]){ 
                    // This checks to see if the alt route is better 
                    //If so, replace current hops!
                    routingTable[j].nexthop = nextNode;
                    routingTable[j].cost = altCost;
                }
                else if (altCost > distance[j] && altCost < routingTable[j].BUcost){
                    //If greater than current distance, but less than its back up
                    //Change up Back Up hop and cost!
                    routingTable[j].BUhop = nextNode;
                    routingTable[j].BUcost = altCost;
                }
            }
        } 
     }

    //  uint8_t start;

        dbg("routing", "Routing table created:\n");
        for (i = 0; i < MAX_NODES; i++) {
        if (routingTable[i].cost != INFINITY) {
            dbg("routing", "Destination: %d, Next Hop: %d, Cost: %d\n", i, routingTable[i].nexthop, routingTable[i].cost);
            if (routingTable[i].BUcost != INFINITY) {
                dbg("routing", "  Backup Hop: %d, Backup Cost: %d\n", routingTable[i].BUhop, routingTable[i].BUcost);
            }
        }
    }
}

     // ------------- LSA STUFF -------
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
            if (lsTable[i].neighborID == inlsa->src && tupleIndex < MAX_TUPLE && lsTable[i].isActive == ACTIVE){
                tempTuple.neighbor = lsTable[i].neighborID;
                tempTuple.cost = lsTable[i].linkQuality;
                inlsa->tupleList[tupleIndex] = tempTuple;
                tupleIndex++;
            }
        }

         fieldSize = sizeof(uint16_t) + sizeof(uint16_t);
         tupleSize = tupleIndex * sizeof(tuple_t);
         paylodSize = fieldSize + tupleSize;
        
        //do this to for the LSAsend
        return payloadSize;


     }

        command void LinkState.getTable(routing_t* tableRoute) {
        uint8_t i;
        for (i = 0; i < MAX_NODES; i++) {
            tableRoute[i] = routingTable[i];
            }
         }

    //  void lsaSize(LSA sizeLSA){
    //     uint8_t fieldSize = sizeof(sizeLSA->src) + sizeof(sizeLSA->seq);
    //     uint8_t tupleSize = tupleIndex * sizeof(tuple_t);
    //     uint8_t paylodSize = fieldSize + tupleSize;

    //  }



}