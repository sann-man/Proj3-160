interface LinkState {
    command error_t start();
    event void NeighborDiscovert.done();
    
}