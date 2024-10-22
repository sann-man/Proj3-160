interface IPmod{
    command error_t send(pack*, uint16_t dest);
    command void start();
    event void packetReceived(pack msg);

}